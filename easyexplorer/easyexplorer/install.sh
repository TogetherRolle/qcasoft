#!/bin/sh
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=$(nvram get productid)
module=easyexplorer
DIR=$(cd $(dirname $0); pwd)

# 获取固件类型
_get_type() {
	local FWTYPE=$(nvram get extendno|grep koolshare)
	if [ -d "/koolshare" ];then
		if [ -n $FWTYPE ];then
			echo "koolshare官改固件"
		else
			echo "koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			echo "梅林原版固件"
		else
			echo "华硕官方固件"
		fi
	fi
}

exit_install(){
	local state=$1
	case $state in
		1)
			echo_date "本插件适用于适用于【koolshare 官改 qca-ipq806x】固件平台，你的固件平台不能安装！！！"
			echo_date "本插件支持机型/平台：https://github.com/koolshare/qcasoft#qcasoft"
			echo_date "退出安装！"
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 1
			;;
		0|*)
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 0
			;;
	esac
}

# 判断路由架构和平台
case $(uname -m) in
	armv7l)
		if [ "$MODEL" == "RT-AX89U" ] && [ -d "/koolshare" ];then
			echo_date 机型：$MODEL $(_get_type) 符合安装要求，开始安装插件！
		else
			exit_install 1
		fi
		;;
	*)
		exit_install 1
	;;
esac
# stop easyexplorer first
enable=`dbus get easyexplorer_enable`
if [ "$enable" == "1" ];then
	killall	easy-explorer > /dev/null 2>&1
fi

rm -rf /koolshare/init.d/*easyexplorer.sh
cp -rf /tmp/easyexplorer/bin/* /koolshare/bin/
cp -rf /tmp/easyexplorer/scripts/* /koolshare/scripts/
cp -rf /tmp/easyexplorer/webs/* /koolshare/webs/
cp -rf /tmp/easyexplorer/res/* /koolshare/res/
cp -rf /tmp/easyexplorer/uninstall.sh /koolshare/scripts/uninstall_easyexplorer.sh
chmod +x /koolshare/bin/easy-explorer
chmod +x /koolshare/scripts/*
[ ! -L "/koolshare/init.d/S99easyexplorer.sh" ] && ln -sf /koolshare/scripts/easyexplorer_config.sh /koolshare/init.d/S99easyexplorer.sh
[ ! -L "/koolshare/init.d/N99easyexplorer.sh" ] && ln -sf /koolshare/scripts/easyexplorer_config.sh /koolshare/init.d/N99easyexplorer.sh

# 离线安装用
dbus set easyexplorer_version="$(cat $DIR/version)"
dbus set softcenter_module_easyexplorer_version="$(cat $DIR/version)"
dbus set softcenter_module_easyexplorer_description="易有云 （EasyExplorer） 跨平台文件同步，支持双向同步！"
dbus set softcenter_module_easyexplorer_install="1"
dbus set softcenter_module_easyexplorer_name="easyexplorer"
dbus set softcenter_module_easyexplorer_title="易有云"

# re-enable easyexplorer
if [ "$enable" == "1" ];then
	sh /koolshare/scripts/easyexplorer_config.sh start
fi

# 完成
echo_date "易有云插件安装完毕！"
exit_install
