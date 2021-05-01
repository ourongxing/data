#!/usr/bin/env bash
export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:$PATH"

# --------------------------------------------------------------
# 原作者信息
#	系统: ALL
#	项目: 蓝奏云上传文件
#	版本: 1.0.3
#	作者: XIU2
#	官网: https://shell.xiu2.xyz
#	项目: https://github.com/XIU2/Shell
# --------------------------------------------------------------
# 修改：ourongxing
# 新增：上传文件夹或不支持上传的文件时自动压缩为 zip，并自动复制分享链接到剪贴板
# 使用：推荐 alias lanzou='bash ~/Desktop/lanzou_up.sh 文件夹id'
# --------------------------------------------------------------

USERNAME="13290031542" # 蓝奏云用户名
COOKIE_PHPDISK_INFO="BDFfbQNhVWwCOFA3CGVWBQZiUlkJYQZiDz4AaQI0VGZXYAc0BWICOg8%2FDldbZQM7AmAHMg5uUGNQagdlDzABZwRhX2wDaVVgAjdQOAg0VjUGYFJkCWYGMA8%2FAGUCPVRnVzIHNgUxAjYPOQ5oWwgDaAJhBzcOblA3UGMHZA84ATYENF9v" # 替换 XXX 为 Cookie 中 phpdisk_info 的值
COOKIE_YLOGIN="1005877" # 替换 XXX 为 Cookie 中 ylogin 的值

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36"
HEADER_CHECK_LOGIN="User-Agent: ${UA}
Referer: https://up.woozooo.com/mydisk.php?item=files&action=index&u=${USERNAME}
Accept-Language: zh-CN,zh;q=0.9"

URL_ACCOUNT="https://pc.woozooo.com/account.php"
URL_UPLOAD="https://up.woozooo.com/fileup.php"

INFO="[信息]" && ERROR="[错误]" && TIP="[注意]"

# 检查是否已登录
_CHECK_LOGIN() {
  if [[ "${COOKIE_PHPDISK_INFO}" = "" || "${COOKIE_PHPDISK_INFO}" = "XXX" ]]; then
    _NOTICE "ERROR" "请指定 Cookie 中 phpdisk_info 的值！"
  fi
  if [[ "${COOKIE_YLOGIN}" = "" || "${COOKIE_YLOGIN}" = "XXX" ]]; then
    _NOTICE "ERROR" "请指定 Cookie 中 ylogin 的值！"
  fi

  HTML_CHECK_LOGIN=$(curl -s --http1.1 -b "ylogin=${COOKIE_YLOGIN};phpdisk_info=${COOKIE_PHPDISK_INFO}" -H "${HEADER_CHECK_LOGIN}" "${URL_ACCOUNT}"|grep "登录")
  [[ ! -z "${HTML_CHECK_LOGIN}" ]]  && _NOTICE "ERROR" "Cookie 已失效，请更新！"
}

# 上传文件
_UPLOAD() {
  HTML_UPLOAD=$(curl --connect-timeout 120 -m 5000 --retry 2 -s -b "ylogin=${COOKIE_YLOGIN};phpdisk_info=${COOKIE_PHPDISK_INFO}" -H "${URL_UPLOAD}" -F "task=1" -F "id=WU_FILE_0" -F "folder_id=${FOLDER_ID}" -F "name=${NAME}" -F "upload_file=@${NAME_FILE}" "${URL_UPLOAD}")
  STATUS=$(echo $HTML_UPLOAD | grep '\\u4e0a\\u4f20\\u6210\\u529f' )
  [[ -z "${STATUS}" ]] && _NOTICE "ERROR" "${NAME} 上传失败！$(echo $HTML_UPLOAD | sed -n 's/.*info":"\([^"]*\)".*$/\1/gp')"
  SHARE_ID=$(echo $HTML_UPLOAD | sed -n 's/.*f_id":"\(\w*\)".*$/\1/gp')
  echo -e "${INFO} 文件上传成功！[$(date '+%Y/%m/%d %H:%M')]"
  echo -n "https://busiyi.lanzous.com/$SHARE_ID" | xclip -selection c
}

_NOTICE() {
  PARAMETER_1="$1"
  PARAMETER_2="$2"
  if [[ ${PARAMETER_1} == "INFO" ]]; then
    echo -e "${INFO} ${PARAMETER_2} [$(date '+%Y/%m/%d %H:%M')]"
  else
    echo -e "${ERROR} ${PARAMETER_2} [$(date '+%Y/%m/%d %H:%M')]"
    exit 1
  fi
}

TYPE="doc,docx,zip,rar,apk,ipa,txt,exe,7z,e,z,ct,ke,cetrainer,db,tar,pdf,w3x,epub,mobi,azw,azw3,osk,osz,xpa,cpk,lua,jar,dmg,ppt,pptx,xls,xlsx,mp3,ipa,iso,img,gho,ttf,ttc,txf,dwg,bat,imazingapp,dll,crx,xapk,conf,deb,rp,rpm,rplib,mobileconfig,appimage,lolgezi,flac,cad,hwt,accdb,ce,xmind,enc,bds,bdi,ssf,it"
FOLDER_ID="$1" # 上传文件夹ID
NAME_FILE="$2" # 文件路径

if [ -d "$NAME_FILE" ]; then
  # 文件夹
  [[ ${NAME_FILE: -1} == / ]] && NAME_FILE=${NAME_FILE%?}
  zip -q -r $NAME_FILE.zip $NAME_FILE
  NAME_FILE=$NAME_FILE.zip
else
  # 文件
  EXT=`basename $NAME_FILE | cut -d . -f2` # 扩展名
  if [[ -z $(echo $TYPE | grep $EXT) ]];then
    zip -q -r $NAME_FILE.zip $NAME_FILE
    NAME_FILE=$NAME_FILE.zip
  fi
fi

NAME=`basename $NAME_FILE`

if [[ $(du "${NAME_FILE}" | awk '{print $1}') -gt $((1024*100)) ]]; then
  _NOTICE "ERROR" "${NAME} 大于 100MB！"
fi


if [[ -z "${FOLDER_ID}" ]]; then
  echo -e "${ERROR} 未指定上传文件夹ID！" && exit 1
elif [[ -z "${NAME_FILE}" ]]; then
  echo -e "${ERROR} 未指定文件路径！" && exit 1
fi

_CHECK_LOGIN
_UPLOAD

# 删除压缩包
[[ $NAME_FILE != $2 ]] && rm $NAME_FILE
