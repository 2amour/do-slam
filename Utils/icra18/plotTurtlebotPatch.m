I = zeros(200,400,3);
I(:,:,3)=0;

I(1:200,1:200,1)=255;
I(1:200,200:400,2)=255;
I(1:200,400:600,3)=255;

imshow(I);