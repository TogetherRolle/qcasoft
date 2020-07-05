#!/bin/sh
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=$(nvram get productid)
module=pushplus
DIR=$(
    cd $(dirname $0)
    pwd
)

# 获取固件类型
_get_type() {
    local FWTYPE=$(nvram get extendno | grep koolshare)
    if [ -d "/koolshare" ]; then
        if [ -n $FWTYPE ]; then
            echo "koolshare官改固件"
        else
            echo "koolshare梅林改版固件"
        fi
    else
        if [ "$(uname -o | grep Merlin)" ]; then
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
# stop pushplus first
enable=$(dbus get pushplus_enable)
if [ "$enable" == "1" ] && [ -f "/koolshare/scripts/pushplus_config.sh" ]; then
    /koolshare/scripts/pushplus_config.sh stop >/dev/null 2>&1
fi

# 安装
echo_date "开始安装pushplus通知..."
cd /tmp
if [[ ! -x /koolshare/bin/jq ]]; then
    cp -f /tmp/pushplus/bin/jq /koolshare/bin/jq
    chmod +x /koolshare/bin/jq
fi
rm -rf /koolshare/init.d/*pushplus.sh
rm -rf /koolshare/pushplus >/dev/null 2>&1
rm -rf /koolshare/scripts/pushplus_*
cp -rf /tmp/pushplus/res/icon-pushplus.png /koolshare/res/
cp -rf /tmp/pushplus/scripts/* /koolshare/scripts/
cp -rf /tmp/pushplus/webs/Module_pushplus.asp /koolshare/webs/
chmod +x /koolshare/scripts/*
# 安装重启自动启动功能
[ ! -L "/koolshare/init.d/S99CRUpushplus.sh" ] && ln -sf /koolshare/scripts/pushplus_config.sh /koolshare/init.d/S99CRUpushplus.sh

# 设置默认值
router_name=$(echo $(nvram get model) | base64_encode)
router_name_get=$(dbus get pushplus_config_name)
if [ -z "${router_name_get}" ]; then
    dbus set pushplus_config_name="${router_name}"
fi
router_ntp_get=$(dbus get pushplus_config_ntp)
if [ -z "${router_ntp_get}" ]; then
    dbus set pushplus_config_ntp="ntp1.aliyun.com"
fi
bwlist_en_get=$(dbus get pushplus_dhcp_bwlist_en)
if [ -z "${bwlist_en_get}" ]; then
    dbus set pushplus_dhcp_bwlist_en="1"
fi
_sckey=$(dbus get pushplus_config_sckey)
if [ -n "${_sckey}" ]; then
    dbus set pushplus_config_sckey_1=$(dbus get pushplus_config_sckey)
    dbus remove pushplus_config_sckey
fi
[ -z "$(dbus get pushplus_info_lan_macoff)" ] && dbus set pushplus_info_lan_macoff="1"
[ -z "$(dbus get pushplus_info_dhcp_macoff)" ] && dbus set pushplus_info_dhcp_macoff="1"
[ -z "$(dbus get pushplus_trigger_dhcp_macoff)" ] && dbus set pushplus_trigger_dhcp_macoff="1"

# 离线安装用
dbus set pushplus_version="$(cat $DIR/version)"
dbus set softcenter_module_pushplus_version="$(cat $DIR/version)"
dbus set softcenter_module_pushplus_install="1"
dbus set softcenter_module_pushplus_name="PushPlus"
dbus set softcenter_module_pushplus_title="PushPlus全能推送"
dbus set softcenter_module_pushplus_description="从路由器推送状态及通知到PushPlus的工具。"

# re-enable pushplus
if [ "$enable" == "1" ] && [ -f "/koolshare/scripts/pushplus_config.sh" ]; then
    /koolshare/scripts/pushplus_config.sh start >/dev/null 2>&1
fi

# 完成
echo_date "pushplus通知插件安装完毕！"
exit_install
