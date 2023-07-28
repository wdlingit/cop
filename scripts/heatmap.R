
library("pheatmap");library("RColorBrewer")

args = commandArgs(trailingOnly=TRUE)

table1 <- read.delim(args[1])
row.names(table1) <- table1$TERM
mtx1 <- data.matrix(table1[,2:ncol(table1)])
hPix <- ifelse(nrow(mtx1) < 50, 800, nrow(mtx1)*20)
png(filename=args[2],width=1600,height=hPix,type="cairo")
pheatmap(mtx1,color=colorRampPalette(rev(brewer.pal(10,"Blues")))(240),treeheight_row=200,fontsize=12)
dev.off()
