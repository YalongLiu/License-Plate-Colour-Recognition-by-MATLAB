%% 初始化
clear;
close all;
matlabpool open;%打开cpu所有核心
corenum = 16;%我这个服务器是16核心的
inputpath = 'C:\卡口数据（总）\卡口数据2017.4.17\';%图片输入路径
outputpath = 'C:\卡口数据（总）\yellow4\';%图片输出路径
Files = dir(fullfile(inputpath,'*.jpg'));%载入每个图片路径信息
LengthFiles = length(Files);%计算文件夹内的图片张数

%% 并行计算配置
for i = 1:corenum:LengthFiles;%16个图像一批，同时处理
    Scolor = Composite();%创建Composite对象
    for j = 1:corenum
        Scolor{j} = imread(strcat(inputpath,Files(i+j-1).name));%为Composite对象进行初始化赋值，即为每个核心分配待处理的图片
        fprintf('Processing:No.%d  %s\n',i+j-1,Files(i+j-1).name);%输出当前状态信息
    end
    
    %% 每个对象都使用的图像处理方法
    spmd
        %Step1 图像截取与黄色区域增强
        Scolor = Scolor(300:end-300,300:end-300,:);%截取图像的中间部分
        Sgray=imsubtract(Scolor(:,:,1),Scolor(:,:,3));%图通道相减
        %将彩色图像转换为黑白并显示
        Sgray_gray = rgb2gray(Scolor);%rgb2gray转换成灰度图
%         figure,imshow(Sgray),title('原始黑白图像');
        %Step2 图像预处理   对Sgray 原始黑白图像进行开操作得到图像背景
        s=strel('disk',17);%strei函数
        Bgray=imopen(Sgray,s);%打开sgray s图像
%         figure,imshow(Bgray);title('背景图像');%输出背景图像
        Egray=imsubtract(Sgray,Bgray);%两幅图相减，用原始图像与背景图像作减法，增强图像
%         figure,imshow(Egray);title('增强黑白图像');%输出黑白图像
        
        %Step3 取得最佳阈值，将图像二值化
        fmax1=double(max(max(Egray)));%egray的最大值并输出双精度型
        fmin1=double(min(min(Egray)));%egray的最小值并输出双精度型
        level=(fmax1-(fmax1-fmin1)/3)/255;%获得最佳阈值
        bw22=im2bw(Egray,level);%转换图像为二进制图像
        bw2=double(bw22);
        
        %Step4 对得到二值图像作开闭操作进行滤波
%         figure,imshow(bw2);title('图像二值化');%得到二值图像
        grd = edge(bw2,'canny');%用canny算子识别强度图像中的边界
%         figure,imshow(grd);title('图像边缘提取');%输出图像边缘
        bg1=imclose(grd,strel('rectangle',[5,19]));%取矩形框的闭运算
%         figure,imshow(bg1);title('图像闭运算[5,19]');%输出闭运算的图像
        se = strel('disk',3);
        grd = imdilate(bg1,se);
        bg1=imclose(grd,strel('rectangle',[5,19]));%取矩形框的闭运算
%         figure,imshow(bg1);title('图像闭运算[5,19]');%输出闭运算的图像
        bg3=imopen(bg1,strel('rectangle',[5,19]));%取矩形框的开运算
%         figure,imshow(bg3);title('图像开运算[5,19]');%输出开运算的图像
        bg2=imopen(bg3,strel('rectangle',[19,1]));%取矩形框的开运算
%         figure,imshow(bg2);title('图像开运算[19,1]');%输出开运算的图像
        
        %Step5 对二值图像进行区域提取，并计算区域特征参数。进行区域特征参数比较，提取车牌区域
        [L,num] = bwlabel(bg2,8);%标注二进制图像中已连接的部分
        Feastats = regionprops(L,'basic');%计算图像区域的特征尺寸
        Area=[Feastats.Area];%区域面积
        if ~isempty(Area)%区域是否为空，即没有黄色区域
            BoundingBox=[Feastats.BoundingBox];%[x y width height]车牌的框架大小
            x = floor(BoundingBox(1));%向下取整，剪切区域时，坐标点不允许有小数
            y = floor(BoundingBox(2));
            width = BoundingBox(3);
            height = BoundingBox(4);
            if x>0 && x < 1800 && y > 0 && y < 1100
                imgcut= Scolor(y:(y+height),x:(x+width),:);%剪切出黄色车牌区域
                % imshow(imgcut);
                imgfinal = imresize(imgcut,[1,1]);%计算颜色均值
                signa = imgfinal(:,:,1);%通道红
                signb = imgfinal(:,:,2);%通道绿
                signc = imgfinal(:,:,3);%通道蓝
                if signa - signc > 80 && signb -signc > 70 && signc < 70 %大致符合黄色
                    copyfile(strcat(inputpath,Files(i+labindex-1).name), strcat(outputpath,Files(i+labindex-1).name));%将符合要求的图片复制到另一个文件夹中
                    fprintf('OK:No.%d %s\n\n',i+labindex-1,Files(i+labindex-1).name);%符合要求的图片信息
                end
            end
        end
    end
end
%% 结束
clear ;
close all;
matlabpool close;%关闭计算核心