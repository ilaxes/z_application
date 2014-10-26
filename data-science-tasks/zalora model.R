library(caret)
library(randomForest)
library(reshape2)
library(e1071)

# ----------------
# Import data train
#
data <- read.csv("/home/alex/Bureau/zalora_application/data-science-tasks/products.csv", header = TRUE, quote = '"' )
vars <- names(data)
summary(data)

# ----------------
# Data preparation
#

# transform date => nb days since product launch
data[,4] <- as.numeric(difftime("2014-10-04",as.Date(as.POSIXct(data[,4], origin="1970-01-01")), 
                                units="days"))

# feature creation
disc_price <- data[,8]
disc_price[is.na(disc_price)] <- data[is.na(disc_price),7]
perc_disc <- (1-(disc_price/data[,7]))*100
br_30 <- log(((data[,20]-data[,19])/(data[,17]-data[,16]) * 1000) + 1)
br_tot <- log(((data[,18]-data[,19])/(data[,15]-data[,16]) * 1000) + 1)
br_tot_re <- data$net_sale_count/data$impressions_count/data$activated_at*1000
target <- log((data[,19] / apply(data[,c(16,19)], 1, max) * 1000) + 1)
data[,8] <- as.numeric(is.na(data[,8]))

# limit number of categories in categorical variables
cat <- which(sapply(data, is.factor))
for (i in 1:length(cat)) {
  levels(data[,cat[i]])[table(data[,cat[i]])<50] <- "Others"
}

# creation training/validation set
trainIndex <- createDataPartition(target, p = .8,
                                  list = FALSE,
                                  times = 1)
data_train <- cbind(data[, c(2:10)], perc_disc, br_30, br_tot, br_tot_re, target)[trainIndex,]
summary(data_train)
data_test <- cbind(data[, c(2:10)], perc_disc, br_30, br_tot, br_tot_re, target)[-trainIndex,]
summary(data_test)


# ----------------
# model training
#

# create evaluation function
kendall <- function (data, lev = NULL, model = NULL)                               
  {out <- cor(data[, "pred"], data[, "obs"], method = "kendall")
     names(out) <- "kendall"
     out
  }
fitControl = trainControl( method = "cv", 
                           number = 10,
                           summaryFunction = kendall,
                           verboseIter = TRUE)
gbmFit <- train(target ~ ., data=data_train,
                method="gbm",
                trControl=fitControl,
                metric = "kendall",
                distribution="laplace",
                verbose=FALSE)
plot(predict(gbmFit, data_train), data_train$target)
plot(predict(gbmFit, data_test), data_test$target)

rfFit <- train(target ~ ., data=data_train,
                method="rf",
                trControl=fitControl,
                metric = "kendall",
                verbose=FALSE)
plot(predict(rfFit, data_train), data_train$target)
plot(predict(rfFit, data_test), data_test$target)

svmFit <- train(target ~ ., data=data_train,
                method = "svmRadial",
                trControl = fitControl,
                metric = "kendall",
                preProc = c("center", "scale"))
plot(predict(svmFit, data_train), data_train$target)
plot(predict(svmFit, data_test), data_test$target)

resamps <- resamples(list(RF = rfFit,
                          GBM = gbmFit,
                          SVM = svmFit))
bwplot(resamps, layout = c(3, 1))


# There seems to be a problem to model products with a 0 conversion rate
# so it would be useful to create a first model to isolate them
data_train_d <- cbind(data[, c(2:10)], perc_disc, br_30, br_tot, br_tot_re, target=as.factor(ifelse(data$net_sale_count_last_7days==0, "X1","X0")))
fitControl = trainControl( method = "cv", 
                           number = 10, 
                           classProbs = TRUE,
                           summaryFunction = twoClassSummary,
                           verboseIter = TRUE)
rfFit_d <- train(target ~ ., data=data_train_d,
               trControl=fitControl,
               method="rf",
               metric = "ROC",
               sampsize=c(261,261),
               .n.tree=500,
               verbose=FALSE)
plot(predict(rfFit_d, data_train_d), data_train_d$target)
