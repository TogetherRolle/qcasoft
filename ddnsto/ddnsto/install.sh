#!/bin/sh
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=$(nvram get productid)
module=ddnsto
DIR=$(cd $(dirname $0); pwd)

remove_install_file(){
	rm -rf /tmp/${module}* >/dev/null 2>&1
}

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

# stop ddnsto first
enable=`dbus get ddnsto_enable`
if [ -n "$enable" ];then
	killall ddnsto >/dev/null 2>&1
fi

# 安装插件
rm -rf /koolshare/init.d/S70ddnsto.sh
cp -rf /tmp/ddnsto/bin/* /koolshare/bin/
cp -rf /tmp/ddnsto/scripts/* /koolshare/scripts/
cp -rf /tmp/ddnsto/webs/* /koolshare/webs/
cp -rf /tmp/ddnsto/res/* /koolshare/res/
cp -rf /tmp/ddnsto/uninstall.sh /koolshare/scripts/uninstall_ddnsto.sh
chmod +x /koolshare/bin/ddnsto
chmod +x /koolshare/scripts/ddnsto*
chmod +x /koolshare/scripts/uninstall_ddnsto.sh
[ ! -L "/koolshare/init.d/S70ddnsto.sh" ] && ln -sf /koolshare/scripts/ddnsto_config.sh /koolshare/init.d/S70ddnsto.sh

# 离线安装用
dbus set ddnsto_version="$(cat $DIR/version)"
dbus set softcenter_module_ddnsto_version="$(cat $DIR/version)"
dbus set ddnsto_title="DDNSTO远程控制"
dbus set ddnsto_client_version=`/koolshare/bin/ddnsto -v`
dbus set softcenter_module_ddnsto_install="1"
dbus set softcenter_module_ddnsto_name="ddnsto"
dbus set softcenter_module_ddnsto_title="ddnsto远程控制"
dbus set softcenter_module_ddnsto_description="ddnsto内网穿透"

# re-enable ddnsto
if [ "$enable" == "1" ];then
	sh /koolshare/scripts/ddnsto_config.sh start
fi

echo_date "ddnsto插件安装完毕！"
exit_install
