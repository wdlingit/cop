
library("ggplot2");

args = commandArgs(trailingOnly=TRUE)

df<-as.data.frame.matrix(read.delim(args[1]))
df$logP<-with(df, -log10(pVal))
hPix <- ifelse(nrow(df) < 50, 800, nrow(df)*20)

png(filename=args[2],width=1600,height=hPix,type="cairo")
gg<-ggplot(df, aes(y=TERM, x=SET))+
geom_point(aes(col=logP,size=count))+
labs(col="-log10(p)")+
scale_color_gradient(low="red",high="blue")+
theme(axis.title.x=element_blank(),axis.title.y=element_blank())+
theme(text=element_text(size=20))
plot(gg)
dev.off()
