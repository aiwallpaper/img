# wallpaper-app img 图库

## 壁纸分类

参考： ./category.md

## AI 出图要求

AI出图默认生成宽高像素： 1440x2560
除了保存原图，同时通过压缩脚本压缩一张 900x1600 的 webp 图片作为缩略图

考虑到屏幕适配裁切，元素主体不要放在图片边缘部分，上下左右预留10~15%的安全区，不要出现人脸、手、文字等关键元素。

除了元素+webp缩略图，还要生成json描述文件，包含分类、prompt、场景、标签、大小等数据库需要的字段。

## 访问地址

通过 jsdelivr cdn 加速访问，拼接格式
https://cdn.jsdelivr.net/gh/aiwallpaper/img@main/{一级分类}/{二级分类}/{日期}/{文件名}.{webp|png|jpeg}
