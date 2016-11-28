#!/bin/sh

echo "~~~~~~~~~~~~~~~~开始执行脚本~~~~~~~~~~~~~~~~"


####################################################################
###################工程信息以及最下面的蒲公英信息########################
#工程名
PROJECTNAME="xxxx"
#需要编译的 targetName
TARGET_NAME="xxxx"
# ADHOC
#证书名#描述文件
ADHOCCODE_SIGN_IDENTITY="xxxxx"
ADHOCPROVISIONING_PROFILE_NAME="xxxx"

#AppStore证书名#描述文件
APPSTORECODE_SIGN_IDENTITY="xxxxx"
APPSTOREADHOCPROVISIONING_PROFILE_NAME="xxxx"

#是否是工作空间
ISWORKSPACE=true
####################################################################

#证书名
CODE_SIGN_IDENTITY=${ADHOCCODE_SIGN_IDENTITY}
#描述文件
PROVISIONING_PROFILE_NAME=${ADHOCPROVISIONING_PROFILE_NAME}


# 开始时间
beginTime=`date +%s`
DATE=`date '+%Y-%m-%d-%T'`

#编译模式 工程默认有 Debug Release 
CONFIGURATION_TARGET=Release
#编译路径
BUILDPATH=~/Desktop/${TARGET_NAME}_${DATE}
#archivePath
ARCHIVEPATH=${BUILDPATH}/${TARGET_NAME}.xcarchive
#输出的ipa目录
IPAPATH=${BUILDPATH}


#导出ipa 所需plist
ADHOCExportOptionsPlist=./ADHOCExportOptionsPlist.plist
AppStoreExportOptionsPlist=./AppStoreExportOptionsPlist.plist

ExportOptionsPlist=${ADHOCExportOptionsPlist}


# 是否上传蒲公英
UPLOADPGYER=false

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
	CODE_SIGN_IDENTITY=${ADHOCCODE_SIGN_IDENTITY}
    PROVISIONING_PROFILE_NAME=${ADHOCPROVISIONING_PROFILE_NAME}
	ExportOptionsPlist=${ADHOCExportOptionsPlist}
	elif [ "$method" = "2" ]
	then
	CODE_SIGN_IDENTITY=${APPSTORECODE_SIGN_IDENTITY}
    PROVISIONING_PROFILE_NAME=${APPSTOREADHOCPROVISIONING_PROFILE_NAME}
	ExportOptionsPlist=${AppStoreExportOptionsPlist}
	else
	echo "参数无效...."
	exit 1
	fi
else
	ExportOptionsPlist=${ADHOCExportOptionsPlist}
fi

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


echo "~~~~~~~~~~~~~~~~开始编译~~~~~~~~~~~~~~~~~~~"


if [ $ISWORKSPACE = true ]
then
# 清理 避免出现一些莫名的错误
xcodebuild clean -workspace ${PROJECTNAME}.xcworkspace \
-configuration \
${CONFIGURATION} -alltargets

#开始构建
xcodebuild archive -workspace ${PROJECTNAME}.xcworkspace \
-scheme ${TARGET_NAME} \
-archivePath ${ARCHIVEPATH} \
-configuration ${CONFIGURATION_TARGET} \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${PROVISIONING_PROFILE_NAME}"
else
# 清理 避免出现一些莫名的错误
xcodebuild clean -xcodeproj ${PROJECTNAME}.xcodeproj \
-configuration \
${CONFIGURATION} -alltargets

#开始构建
xcodebuild archive -xcodeproj ${PROJECTNAME}.xcodeproj \
-scheme ${TARGET_NAME} \
-archivePath ${ARCHIVEPATH} \
-configuration ${CONFIGURATION_TARGET} \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${PROVISIONING_PROFILE_NAME}"
fi

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
open $BUILDPATH
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


echo "~~~~~~~~~~~~~~~~配置信息~~~~~~~~~~~~~~~~~~~"
echo "开始执行脚本时间: ${DATE}"
echo "编译模式: ${CONFIGURATION_TARGET}"
echo "导出ipa配置: ${ExportOptionsPlist}"
echo "打包文件路径: ${ARCHIVEPATH}"
echo "导出ipa路径: ${IPAPATH}"

echo "$ArchiveTime"
echo "$ExportTime"
exit 1

