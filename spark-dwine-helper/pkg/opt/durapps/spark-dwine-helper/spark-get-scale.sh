#/bin/bash
##### $1是容器位置

if [ "$1" = "" ];then
echo "错误：没有输入容器地址。请参考set-dwine5-scale对本脚本的调用"
exit 
fi



Get_Dist_Name()
{
    if grep -Eqii "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
        DISTRO='Deepin'
    elif grep -Eqi "Uniontech" /etc/issue || grep -Eq "Uniontech" /etc/*-release; then
        DISTRO='UniontechOS'

	fi
}
Get_Dist_Name
if [ "$DISTRO" = "Deepin" ] || [ "$DISTRO" = "UniontechOS" ];then
return 1.0
#####就是1倍缩放
exit
fi

if [ -f "$1/scale.txt" ];then
return `cat $1/scale.txt`
exit
fi

dimensions=`xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/'`

zenity --list \
	--width=700 \
	--height=300 \
       --title="您的分辨率是：$dimensions，请在以下选项中选择一个以运行应用" \
       --column="缩放倍率" \
       1.0 \
       1.25 \
	1.5 \
       2.0
zenity --info --text="已保存！您可以随时删除$1/scale.txt来重新设置"
echo "$?" > $1/scale.txt
return $?
