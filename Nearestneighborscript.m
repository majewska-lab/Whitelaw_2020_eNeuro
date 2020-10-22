X = [p2y.Area p2y.Y]
 figure;
x = squeeze(X(:,1));
y = squeeze(X(:,2));
scatter(x,y);
[Idx, D] = knnsearch(X,X,'K',2);