## iOS自动打包及上传蒲公英

### 20170927 更新记录
该版本做了2处修改：
 - 使用了fastlane来运行gym
 - 编译前添加一个字段PgyUpdate到项目的Info.plist中，编译结束后删除该字段，这样可以保证当前的包Info.plist中含有PgyUpdate字段。之所以加这个字段是为了配合[LEUpdateFromPgyer](https://github.com/LarryEmerson/LEUpdateFromPgyer)(app自动检测版本并更新)
 ### 必要配置
 - 项目中确保Info.plist中的“Bundle versions string, short”为“1.0.0”的标准版本号，“Bundle version”为“1”整形
 - BuildPhases中添加新的Shell
 
 ```
 buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFOPLIST_FILE")
 buildNumber=$(($buildNumber + 1))
 /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$INFOPLIST_FILE"
 ```
 - fastlane 安装： sugo gem install fastlane
#### 以下是分割线
---

github找了很久自动打包的脚本（shell，python），最后我测试成功的只有2个（1：https://github.com/735344577/build，2：https://github.com/hytzxd/iOS-AutoBuild）。 相比而言1更加简便，2则配置化太发杂和繁琐。最后选择了1，也就是当前的版本作为以后的自动打包及上传的工具。

在作者原版本的基础上，我添加了根目录设置（支持自动识别根目录及外部项目绝对路径设置，这样当前的脚本也可以脱离项目而存在且可以多个项目共享）、蒲公英key的检测与补救输入及上传蒲公英的功能。由于蒲公英支持邮件通知，因此没有添加邮件功能。 
 
###使用前准备工作：
``` 
安装pip
sudo easy_install pip
安装json-query
pip install json-query 
安装 gym
pip install gym
```
###使用方法：
######(目前默认支持development模式，其他模式请修改配置，尚未测试其他模式)
1-下载pkgtopgy.sh至任意目录 
2-终端新建窗口 输入sh （sh+空格），然后拖入文件 pkgtopgy.sh 回车
（也可以右击-显示简介-打开方式设置为终端，然后双击打开）
####运行终端截取：
 ```
请确认当前目录为项目根目录：/Users/LarryEmerson?(y/n)n
请输入项目目录的绝对路径:/Volumes/MacHD/LarryEmerson/RemoteGits/xx/
/Volumes/MacHD/LarryEmerson/RemoteGits/xx/
Print: Entry, "LEPgyerApiKey", Does Not Exist
Print: Entry, "LEPgyerUKey", Does Not Exist 
发现尚未配置蒲公英上传的apiKey及ukey,是否配置?(y/n)y
请输入蒲公英上传的apiKey:xxxxxxxxxxxxxxxxx
请输入蒲公英上传的ukey:xxxxxxxxxxxxxxxxxx
/Users/LarryEmerson/Desktop/xx_2016_10_25_15_36_05
=================AutoPackageBuilder===============
begin package at 2016_10_25_15_36_05
。。。。。。
[15:36:39]: /Users/LarryEmerson/Desktop/xx_2016_10_25_15_36_05/xx_2016_10_25_15_36_05.ipa
==================>Finished. Total time: 39s 
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 51579  100   602  100 50977    346  29364  0:00:01  0:00:01 --:--:-- 29364
http://www.pgyer.com/xx
本次打包完成
```


