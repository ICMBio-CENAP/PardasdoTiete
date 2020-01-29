## Figures for comparing SSF with maxent

ssf <- readRDS(paste0(experiment.folder, "/dataderived/bestmodels.rds"))

evallist <- list()
preds.pa <- list()
for( a in 1:nrow(ssf)) {
    model <- ssf$fit[[a]]
    trk <- ssf$trk[[a]]
    test <- trk %>% filter(!train)
    preds <- predict(model$model, newdata=test, type="risk", reference="sample" )
    preds <- preds/(1+preds)
    iscase <- pull(test,"case_")
    evaluation <- evaluate( preds[iscase], preds[!iscase] )
    evallist[[a]] <- evaluation
    preds.pa[[a]] <- cbind(preds,iscase)
}
preds.pa <- do.call(rbind,preds.pa)
boxplot(preds~iscase,data=preds.pa,xaxt="n",notch=T)
axis(1,at=1:2,labels =c("absence","presence"))

maxent <- readRDS(paste0(experiment.folder, "/dataderived/experiment.maxent.rds"))
boxplot(maxent)