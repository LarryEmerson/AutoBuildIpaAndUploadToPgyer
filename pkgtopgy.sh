#!/bin/sh
#LEPgyerApiKey 在Info.plist中配置蒲公英apiKey
#LEPgyerUKey 在Info.plist中配置蒲公英ukey

result=''
uploadToPgyer()
{
	echo "蒲公英上传配置：" 
	echo "ipa路径:  " $1
	echo "UserKey: " $2
	echo "ApiKey:  " $3
	echo "Password:" $4
	
	result=$(curl -F "file=@$1" -F "uKey=$2" -F "_api_key=$3" -F "publishRange=2" -F "isPublishToPublic=2" -F "installType=2" -F "password=$4" 'https://www.pgyer.com/apiv1/app/upload' | json-query data.appShortcutUrl)
}

tempPath="$(pwd)" 
pathConfig="${tempPath}/pkgtopgy_path.config"
pgyConfig="${tempPath}/pgyer.config"
#判定并创建历史打包目录配置文件
if [ ! -f $pathConfig ] ; then 
	touch $pathConfig
fi
#判定并创建蒲公英配置文件
if [ ! -f $pgyConfig ] ; then 
	touch $pgyConfig
fi
#历史打包目录条数
lines=`sed -n '$=' ${pathConfig}` 

if [[ $lines == '' ]]; then
	lines=0
fi  

echo "请选择你需要打包的目录："
for i in `cat ${pathConfig} `
do
	echo  $((++no)) ":" $i
done
echo  $((++no)) ":" "${tempPath}"
	 
read -p "请选择打包目录(若无合适的目录请直接回车)：" pathselection
if [[ $pathselection >0 ]] && [[ $pathselection -le `expr $lines+1` ]] ; then
	if [[ $pathselection -le $lines ]] ; then
		project_path=`sed -n ${pathselection}p ${pathConfig}` 
	else 
		echo "已选目录：${tempPath}" 
		read -p "请确认上述已选目录：(y/n)" checkPath
		if [[ $checkPath = "y" ]] ; then
			project_path=$tempPath
		fi
	fi 
else
	echo "未找到合适的路径"
fi	

if [[ $project_path == '' ]]; then 
	read -p "请手动输入打包工程的绝对路径:" inputPath
	project_path=$inputPath
	if [[ $project_path != '' ]]; then 
		echo $project_path >> ${pathConfig}
		cat ${pathConfig}
	fi
fi


if [[ -d "$project_path" ]]; then
	echo "当前路径为：" $project_path
else
	echo "路径："$project_path
	echo "当前路径有误，已终止!!!\n"
	# exit
fi
SECONDS=0
#取当前时间字符串添加到文件结尾
now=$(date +"%Y_%m_%d_%H_%M_%S")
#工程名
cd ${project_path}
project=$(ls | grep xcodeproj | awk -F.xcodeproj '{print $1}')
#指定项目地址
isWorkspace = 0
workspace_path="$project_path/${project}.xcworkspace"
if [[ ! -d "$workspace_path" ]]; then
	echo "路径："$workspace_path
	echo "未找到.xcworkspace文件，尝试${project}.xcodeproj"
	# exit
	workspace_path="$project_path/${project}.xcodeproj"
	if [[ ! -d "$workspace_path" ]]; then
		echo "路径："$workspace_path
		echo "未找到.xcodeproj文件，已终止!!!"
		# exit
	fi
else
	isWorkspace = 1
fi
#工程配置文件路径
echo "检查蒲公英设置"
project_infoplist_path=${project_path}/${project}/Info.plist
pgyerApiKey=''
pgyerUKey=''
pgyerApiKey=$(/usr/libexec/PlistBuddy -c "print LEPgyerApiKey" ${project_infoplist_path})
pgyerUKey=$(/usr/libexec/PlistBuddy -c "print LEPgyerUKey" ${project_infoplist_path})
pgyerPassword=$(/usr/libexec/PlistBuddy -c "print LEPgyerPassword" ${project_infoplist_path})
if [[ $pgyerUKey = '' ]] || [[ $pgyerApiKey = '' ]]; then
	i=0
	for line in `cat ${pgyConfig}`;
	do 
		pgy_line_array[i++]=$line
	done
	
	lines=${#pgy_line_array[@]}  
	if [[ $lines > 0 ]]; then 
		echo "发现历史蒲公英配置："
		no=0
		for line in `cat ${pgyConfig}`;
			do    
			api=`echo ${line}|awk -F ',' '{print $1}'`
			user=`echo ${line}|awk -F ',' '{print $2}'`
			psw=`echo ${line}|awk -F ',' '{print $3}'`
			name=`echo ${line}|awk -F ',' '{print $4}'`  
			echo $((++no))"-别名：${name}" 
			echo "    PgyApiKey: ${api} PgyUserKey: ${user} PgyerPassword: ${psw}"  
		done
		read -p "请选择蒲公英配置(若无合适的配置请直接回车)：" pgyindex
		if [[ $pgyindex >0 ]] && [[ $pgyindex -le `expr $lines+1` ]] ; then
			index=$(($pgyindex-1)) 
			str=${pgy_line_array[$index]}  
			pgyerApiKey=`echo ${str}|awk -F ',' '{print $1}'`
			pgyerUKey=`echo ${str}|awk -F ',' '{print $2}'`
			pgyerPassword=`echo ${str}|awk -F ',' '{print $3}'`
			name=`echo ${str}|awk -F ',' '{print $4}'` 
			echo "当前选择蒲公英配置:${name}"
			echo "PgyApiKey: ${pgyerApiKey} PgyUserKey: ${pgyerUKey} PgyerPassword: ${pgyerPassword}" 
		fi
	fi
		
	isCheckPgy=0
	while [ $isCheckPgy == 0 ]
	do 
		if [[ $pgyerUKey = '' ]] || [[ $pgyerApiKey = '' ]]; then
			read -p "发现尚未配置蒲公英上传的apiKey及ukey,是否配置?(y/n)" checkConfig
			if [[ $checkConfig = "y" ]] ; then
				read -p "请输入蒲公英上传的apiKey:" apikey
				pgyerApiKey=$apikey
				read -p "请输入蒲公英上传的ukey:" ukey
				pgyerUKey=$ukey
				if [[ $pgyerUKey != '' ]] || [[ $pgyerApiKey != '' ]]; then
				
					if [[ $pgyerPassword = '' ]]; then
						echo '发现蒲公英下载密码，未在工程项目的Info.plist配置，配置名称为LEPgyerPassword'
						read -p "是否现在配置?(y/n)" checkpsw
						if [[ $checkpsw = "y" ]] ; then 
							read -p "蒲公英下载密码：" inputpsw
							pgyerPassword=$inputpsw
						fi
					fi
					
					read -p "请设置该配置的别名：" name
					pgyerName=$name 
					echo $pgyerApiKey,$pgyerUKey,$pgyerPassword,$pgyerName >> ${pgyConfig} 
					echo ""
					isCheckPgy=1
				fi 
			else
				isCheckPgy=1
			fi
		else
			isCheckPgy=1
		fi
	done 
fi 
#指定项目的scheme名称
scheme=$project
#指定要打包的配置名
configuration="Release"
#指定打包所使用的输出方式，目前支持app-store, package, ad-hoc, enterprise, development, 和developer-id，即xcodebuild的method参数
export_method='development'
#export_method='app-store'

#指定输出路径 _${now}
mkdir "${HOME}/Desktop/${project}"
output_path="${HOME}/Desktop/${project}"
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
echo "workspace path: ${workspace_path}"
echo "archive path: ${archive_path}"
echo "ipa path: ${ipa_path}"
echo "export method: ${export_method}"
echo "commit msg: $1"

/usr/libexec/PlistBuddy -c 'Add PgyUpdate string' ${project_infoplist_path}
/usr/libexec/PlistBuddy -c 'Set PgyUpdate @"itms-services://?action=download-manifest&url=https://www.pgyer.com/app/plist/%@"' ${project_infoplist_path}

#pod update
#pod update --no-repo-update
#先清空前一次build
#gym --workspace ${workspace_path} --scheme ${scheme} --clean --configuration ${configuration} --archive_path ${archive_path} --export_method ${export_method} --output_directory ${output_path} --output_name ${ipa_name}
if [ isWorkspace = 1 ]; then
	fastlane gym --workspace ${workspace_path} --scheme ${scheme} --clean --configuration ${configuration} --export_method ${export_method} --output_directory ${output_path} --output_name ${ipa_name}
else
	fastlane gym --project ${workspace_path} --scheme ${scheme} --clean --configuration ${configuration} --export_method ${export_method} --output_directory ${output_path} --output_name ${ipa_name}
fi
# fastlane gym --workspace ${workspace_path} --scheme ${scheme} --clean --configuration ${configuration} --export_method ${export_method} --output_directory ${output_path} --output_name ${ipa_name}
#输出总用时
echo "==================>Finished. Total time: ${SECONDS}s" 
/usr/libexec/PlistBuddy -c "Delete PgyUpdate" ${project_infoplist_path}
uploadTimeLeft=3
if [[ $pgyerUKey = '' ]] || [[ $pgyerApiKey = '' ]]; then
	echo "因未设置蒲公英上传配置，已取消上传。您可以在工程项目的Info.plist文件中配置LEPgyerApiKey（蒲公英apiKey）、LEPgyerUKey（蒲公英userKey）及LEPgyerPassword（密码）。"
else 
	if [[ -f "$ipa_path" ]]; then
		uploadToPgyer $ipa_path $pgyerUKey $pgyerApiKey $pgyerPassword 
		while [[ $result == '' ]]
		do
			$uploadTimeLeft=$uploadTimeLeft-1
			if [ $uploadTimeLeft <= 0 ] ; then
				read -p "上传失败，是否重新上传到蒲公英?(y/n)" reUploadToPgyer
				if [[ $reUploadToPgyer = "y" ]] ; then
					uploadToPgyer $ipa_path $pgyerUKey $pgyerApiKey $pgyerPassword
				else
					echo "本次打包完成，ipa位置: ${ipa_path}" 
					# exit
				fi
			else
				uploadToPgyer $ipa_path $pgyerUKey $pgyerApiKey $pgyerPassword
			fi
		done
		if [[ $result != '' ]]; then
			echo "请前往此处下载最新的app" http://www.pgyer.com/$result
			open http://www.pgyer.com/$result
		fi 
	fi
fi
echo "本次打包完成"
# exit
