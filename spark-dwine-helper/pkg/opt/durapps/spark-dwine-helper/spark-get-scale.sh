#/bin/bash

mkdir -p ~/.config/spark-wine/


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
echo 1.0 > ~/.config/spark-wine/scale.txt
#####就是1倍缩放
exit
fi

if [ -f "~/.config/spark-wine/scale.txt" ];then
echo "设置过了，直接读"
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
zenity --info --text="已保存！您可以随时删除~/.config/spark-wine/scale.txt来重新设置"
echo "$?" > ~/.config/spark-wine/scale.txt

