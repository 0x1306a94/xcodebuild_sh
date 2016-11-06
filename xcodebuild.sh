#!/bin/sh

echo "~~~~~~~~~~~~~~~~开始执行脚本~~~~~~~~~~~~~~~~"


# 开始时间
beginTime=`date +%s`
DATE=`date '+%Y-%m-%d-%T'`
#需要编译的 targetName
TARGET_NAME="xxxx"
#编译模式 工程默认有 Debug Release 
CONFIGURATION_TARGET=Release
#编译路径
BUILDPATH=~/Desktop/${TARGET_NAME}_${DATE}
#archivePath
ARCHIVEPATH=${BUILDPATH}/${TARGET_NAME}.xcarchive
#输出的ipa目录
IPAPATH=${BUILDPATH}

#证书名
CODE_SIGN_IDENTITY="xxxxx"
#描述文件
PROVISIONING_PROFILE_NAME="xxxx"

#苹果账号
AppleID="xxxx"
AppleIDPWD="xxxx"

#导出ipa 所需plist
ADHOCExportOptionsPlist=./ADHOCExportOptionsPlist.plist
AppStoreExportOptionsPlist=./AppStoreExportOptionsPlist.plist

ExportOptionsPlist=${ADHOCExportOptionsPlist}


# 是否上传蒲公英
UPLOADPGYER=false
# 是否上传AppStore
UPLOADAPPSTore=false

echo "~~~~~~~~~~~~~~~~选择打包方式~~~~~~~~~~~~~~~~"
echo "		1 ad-hoc (默认)"
echo "		2 AppStore "

# 读取用户输入并存到变量里
read parameter
sleep 0.5
method="$parameter"

# 判读用户是否有输入 
if [ -n "$method" ]
then
	if [ "$method" = "1" ]
	then 
	PROVISIONING_PROFILE_NAME="xxxx"
	ExportOptionsPlist=${ADHOCExportOptionsPlist}
	elif [ "$method" = "2" ]
	then
	UPLOADAPPSTore=true
	PROVISIONING_PROFILE_NAME="xxxx"
	ExportOptionsPlist=${AppStoreExportOptionsPlist}
	else
	echo "参数无效...."
	exit 1
	fi
else
	ExportOptionsPlist=${ADHOCExportOptionsPlist}
fi

if [ $UPLOADAPPSTore = false ]
then
	echo "~~~~~~~~~~~~~~~~是否上传蒲公英~~~~~~~~~~~~~~~~"
	echo "		1 不上传 (默认)"
	echo "		2 上传 "
	read para
	sleep 0.5

	if [ -n "$para" ]
	then
		if [ "$para" = "1" ]
		then 
		UPLOADPGYER=false
		elif [ "$para" = "2" ]
		then
		UPLOADPGYER=true
		else
		echo "参数无效...."
		exit 1
		fi
	else
		UPLOADPGYER=false
	fi
fi


echo "~~~~~~~~~~~~~~~~开始编译~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~开始清理~~~~~~~~~~~~~~~~~~~"
# 清理 避免出现一些莫名的错误
xcodebuild clean -workspace ${TARGET_NAME}.xcworkspace \
-configuration \
${CONFIGURATION} -alltargets

echo "~~~~~~~~~~~~~~~~开始构建~~~~~~~~~~~~~~~~~~~"
#开始构建
xcodebuild archive -workspace ${TARGET_NAME}.xcworkspace \
-scheme ${TARGET_NAME} \
-archivePath ${ARCHIVEPATH} \
-configuration ${CONFIGURATION_TARGET} \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${PROVISIONING_PROFILE_NAME}"

echo "~~~~~~~~~~~~~~~~检查是否构建成功~~~~~~~~~~~~~~~~~~~"
# xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断
if [ -d "$ARCHIVEPATH" ]
then
echo "构建成功......"
else
echo "构建失败......"
rm -rf $BUILDPATH
exit 1
fi
endTime=`date +%s`
ArchiveTime="构建时间$[ endTime - beginTime ]秒"


echo "~~~~~~~~~~~~~~~~导出ipa~~~~~~~~~~~~~~~~~~~"

beginTime=`date +%s`

xcodebuild -exportArchive \
-archivePath ${ARCHIVEPATH} \
-exportOptionsPlist ${ExportOptionsPlist} \
-exportPath ${IPAPATH}

echo "~~~~~~~~~~~~~~~~检查是否成功导出ipa~~~~~~~~~~~~~~~~~~~"
IPAPATH=${IPAPATH}/${TARGET_NAME}.ipa
if [ -f "$IPAPATH" ]
then
echo "导出ipa成功......"
else
echo "导出ipa失败......"
# 结束时间
endTime=`date +%s`
echo "$ArchiveTime"
echo "导出ipa时间$[ endTime - beginTime ]秒"
exit 1
fi

endTime=`date +%s`
ExportTime="导出ipa时间$[ endTime - beginTime ]秒"

# 上传AppStore
if [ $UPLOADAPPSTore = true ]
then	

	altoolPath="/Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
	${altoolPath} --validate-app \
	-f ${IPAPATH} \
	-u ${AppleID} \
	-p ${AppleIDPWD} \
	-t ios --output-format xml

		if [ $? = 0 ]
		then
		echo "~~~~~~~~~~~~~~~~验证ipa成功~~~~~~~~~~~~~~~~~~~"
			${altoolPath} --upload-app \
			-f ${IPAPATH} \
			-u ${AppleID} \
			-p ${AppleIDPWD} \
			-t ios --output-format xml

			if [ $? = 0 ]
			then
			echo "~~~~~~~~~~~~~~~~提交AppStore成功~~~~~~~~~~~~~~~~~~~"
			else
			echo "~~~~~~~~~~~~~~~~提交AppStore失败~~~~~~~~~~~~~~~~~~~"
			fi
		else
		echo "~~~~~~~~~~~~~~~~验证ipa失败~~~~~~~~~~~~~~~~~~~"
		fi
else
	# 上传蒲公英	
	if [ $UPLOADPGYER = true ]
	then
		echo "~~~~~~~~~~~~~~~~上传ipa到蒲公英~~~~~~~~~~~~~~~~~~~"
		curl -F "file=@$IPAPATH" \
		-F "uKey=xxxxx" \
		-F "_api_key=xxxx" \
		-F "password=xxxxx" \
		-F "isPublishToPublic=xxxx" \
		https://www.pgyer.com/apiv1/app/upload --verbose

		if [ $? = 0 ]
		then
		echo "~~~~~~~~~~~~~~~~上传蒲公英成功~~~~~~~~~~~~~~~~~~~"
		else
		echo "~~~~~~~~~~~~~~~~上传蒲公英失败~~~~~~~~~~~~~~~~~~~"
		fi
	fi
fi



echo "~~~~~~~~~~~~~~~~配置信息~~~~~~~~~~~~~~~~~~~"
echo "开始执行脚本时间: ${DATE}"
echo "编译模式: ${CONFIGURATION_TARGET}"
echo "导出ipa配置: ${ExportOptionsPlist}"
echo "打包文件路径: ${ARCHIVEPATH}"
echo "导出ipa路径: ${IPAPATH}"

echo "$ArchiveTime"
echo "$ExportTime"
exit 1

