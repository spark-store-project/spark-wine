#/bin/bash
#########>>>>>>>函数段
Get_Dist_Name()
{
    if grep -Eqii "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
        DISTRO='Deepin'
    elif grep -Eqi "Uniontech" /etc/issue || grep -Eq "Uniontech" /etc/*-release; then
        DISTRO='UniontechOS'
    else
	 DISTRO='OtherOS'
	fi
}
#########<<<<<<<

if [ $# -lt 1 ]; then
echo "无参数，无法启动。请参考set-dwine-scale.sh使用"
echo "参数为CONTAINER_PATH"
echo "只读取第一个，其他参数会被放弃"
fi

CONTAINER_PATH="$1"

mkdir -p $HOME/.config/spark-wine/
#####全局参数位置
#####能到这一步的说明已经是没有自定义参数了，直接读全局覆盖没问题
#####

if [ -f "$HOME/.config/spark-wine/scale.txt" ];then
	cat $HOME/.config/spark-wine/scale.txt > $CONTAINER_PATH/scale.txt
	echo "检测到已经设置过全局参数，直接复制"
	exit
fi


Get_Dist_Name
if [ "$DISTRO" = "Deepin" ] || [ "$DISTRO" = "UniontechOS" ];then
echo 1.0 > $HOME/.config/spark-wine/scale.txt
cat $HOME/.config/spark-wine/scale.txt > $CONTAINER_PATH/scale.txt
#####就是1倍缩放
exit
fi



dimensions=`xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/'`
scale_factor=`zenity --list \
	--width=700 \
	--height=350 \
       --title="您的分辨率是：$dimensions，请在以下选项中选择一个以运行应用" \
       --column="缩放倍率" \
       1.0 \
       1.25 \
	1.5 \
	1.75 \
       2.0`

case "$scale_factor" in 
	"")
	zenity --info --text="默认为1倍缩放。您可以随时删除~/.config/spark-wine/scale.txt来重新设置" --width=500 --height=150
	scale_factor="1.0"
	;;
	*)
zenity --info --text="缩放倍数为$scale_factor。已保存！您可以随时删除~/.config/spark-wine/scale.txt来重新设置" --width=500 --height=150
	;;
esac
echo "$scale_factor" > $HOME/.config/spark-wine/scale.txt
cat $HOME/.config/spark-wine/scale.txt > $CONTAINER_PATH/scale.txt

