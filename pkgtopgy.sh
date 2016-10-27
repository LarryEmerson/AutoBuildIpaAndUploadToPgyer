#!/bin/sh
#LEPgyerApiKey  在Info.plist中配置蒲公英apiKey
#LEPgyerUKey    在Info.plist中配置蒲公英ukey

tempPath="$(pwd)"
read -p "请确认当前目录为项目根目录：${tempPath}?(y/n)" checkPath
if [[ $checkPath = "y" ]] ;  then
project_path=$tempPath
else
read -p "请输入项目目录的绝对路径:" inputPath
project_path=$inputPath
fi
if [[ -d "$project_path" ]]; then
echo "当前路径为：" $project_path
else
echo "路径："$project_path
echo "当前路径有误，已终止!!!\n"
exit
fi
SECONDS=0
#取当前时间字符串添加到文件结尾
now=$(date +"%Y_%m_%d_%H_%M_%S")
#工程名
cd ${project_path}
project=$(ls | grep xcodeproj | awk -F.xcodeproj '{print $1}')
#指定项目地址
workspace_path="$project_path/${project}.xcworkspace"
if [[ ! -d "$workspace_path" ]]; then
echo "路径："$workspace_path
echo "未找到.xcworkspace文件，已终止!!!"
exit
fi
#工程配置文件路径
project_infoplist_path=${project_path}/${project}/Info.plist
pgyerApiKey=''
pgyerUKey=''
pgyerApiKey=$(/usr/libexec/PlistBuddy -c "print LEPgyerApiKey" ${project_infoplist_path})
pgyerUKey=$(/usr/libexec/PlistBuddy -c "print LEPgyerUKey" ${project_infoplist_path})
if [[ $pgyerUKey = '' ]] || [[ $pgyerApiKey = '' ]]; then
read -p "发现尚未配置蒲公英上传的apiKey及ukey,是否配置?(y/n)" checkConfig
if [[ $checkConfig = "y" ]] ;  then
read -p "请输入蒲公英上传的apiKey:" apikey
pgyerApiKey=$apikey
read -p "请输入蒲公英上传的ukey:" ukey
pgyerUKey=$ukey
else
read -p "是否继续打包?(y/n)" checkPkg
if [[ $checkPkg = "n" ]] ;  then
exit
fi
fi
fi

#指定项目的scheme名称
scheme=$project
#指定要打包的配置名
configuration="Release"
#指定打包所使用的输出方式，目前支持app-store, package, ad-hoc, enterprise, development, 和developer-id，即xcodebuild的method参数
export_method='development'
#export_method='app-store'

#指定输出路径
mkdir "${HOME}/Desktop/${project}_${now}"
output_path="${HOME}/Desktop/${project}_${now}"
echo $output_path
#指定输出归档文件地址
archive_path="$output_path/${project}_${now}.xcarchive"
#指定输出ipa地址
ipa_path="$output_path/${project}_${now}.ipa"
#指定输出ipa名称
ipa_name="${project}_${now}.ipa"
#获取执行命令时的commit message
commit_msg="$1"
#输出设定的变量值
echo "=================AutoPackageBuilder==============="
echo "begin package at ${now}"
echo "workspace path:  ${workspace_path}"
echo "archive path:    ${archive_path}"
echo "ipa path:        ${ipa_path}"
echo "export method:   ${export_method}"
echo "commit msg:      $1"
#pod update
pod update --no-repo-update
#先清空前一次build
#gym --workspace ${workspace_path} --scheme ${scheme} --clean --configuration ${configuration} --archive_path ${archive_path} --export_method ${export_method} --output_directory ${output_path} --output_name ${ipa_name}
gym --workspace ${workspace_path} --scheme ${scheme} --clean --configuration ${configuration} --export_method ${export_method} --output_directory ${output_path} --output_name ${ipa_name}
#输出总用时
echo "==================>Finished. Total time: ${SECONDS}s"
#打开包所在目录
if [[ $pgyerUKey = '' ]] || [[ $pgyerApiKey = '' ]]; then
echo "未在工程项目的Info.plist文件中配置LEPgyerApiKey（蒲公英apiKey）及LEPgyerUKey（蒲公英userKey），因此无法上传项目至蒲公英平台"
else
if [[ -f "$ipa_path" ]]; then
result=$(curl -F "file=@$ipa_path" -F "uKey=$pgyerUKey" -F "_api_key=$pgyerApiKey" -F "publishRange=2" -F "isPublishToPublic=2" -F "password=$pgyPassword"  'https://www.pgyer.com/apiv1/app/upload' | json-query data.appShortcutUrl)
fi
echo "请前往此处下载最新的app" http://www.pgyer.com/$result
if [[ $result != '' ]]; then
open http://www.pgyer.com/$result
fi
fi
echo "本次打包完成"