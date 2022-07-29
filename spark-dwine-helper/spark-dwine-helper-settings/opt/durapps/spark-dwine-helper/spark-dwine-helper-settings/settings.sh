#/bin/bash


until [ "$IS_CLOSE" = "1" ];do

CHOSEN_SETTINGS=`zenity --list \
	--width=700 \
	--height=350 \
       --title="欢迎使用星火wine助手控制中心，请在以下选项中选择一个执行！" \
       --column="操作" \
	设置全局缩放 \
       设置单独应用缩放 \
	备注：以上操作仅对使用了spark-dwine-helper的应用生效 `

echo "$CHOSEN_SETTINGS"
case "$CHOSEN_SETTINGS" in 
	"设置全局缩放")
########
	zenity --info --text="请注意：此选项对deepin/UOS无效，会优先读取deepin/UOS的缩放设置进行缩放" --width=500 --height=150

dimensions=`xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/'`
scale_factor=`zenity --list \
	--width=700 \
	--height=350 \
       --title="您的分辨率是：$dimensions，请在以下选项中选择一个" \
       --column="缩放倍率" \
       1.0 \
       1.25 \
	1.5 \
	1.75 \
       2.0`

case "$scale_factor" in 
	"")
	zenity --info --text="默认为1倍缩放。" --width=500 --height=150
	scale_factor="1.0"
	;;
	*)
zenity --info --text="缩放倍数为$scale_factor。已保存！" --width=500 --height=150
	;;
esac
echo "$scale_factor" > $HOME/.config/spark-wine/scale.txt


	;;
########




	"设置单独应用缩放")
	zenity --info --text="请在接下来的文件选择框选中所需的应用所在的容器文件夹（注意要选择文件夹）" --width=500 --height=150
	CONTAINER_PATH=`zenity --file-selection --filename="$HOME/.deepinwine/" --directory`
	
	if [ ! -f "$CONTAINER_PATH/user.reg" ];then
	zenity --info --text="错误：找不到user.reg.这不是一个wine容器" --width=500 --height=150
	
	else
	
	dimensions=`xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/'`
scale_factor=`zenity --list \
	--width=700 \
	--height=350 \
       --title="您的分辨率是：$dimensions，请在以下选项中选择一个" \
       --column="缩放倍率" \
       1.0 \
       1.25 \
	1.5 \
	1.75 \
       2.0 \
	与全局设置同步 `

case "$scale_factor" in 
	"")
	zenity --info --text="默认为1倍缩放。" --width=500 --height=150
	scale_factor="1.0"
/opt/durapps/spark-dwine-helper/scale-set-helper/set-wine-scale.sh -s $scale_factor $CONTAINER_PATH
	;;
	"与全局设置同步")
	zenity --info --text="将会与全局设置同步" --width=500 --height=150
	rm $CONTAINER_PATH/scale.txt
	;;
	*)
zenity --info --text="缩放倍数为$scale_factor。已保存！" --width=500 --height=150
/opt/durapps/spark-dwine-helper/scale-set-helper/set-wine-scale.sh -s $scale_factor $CONTAINER_PATH
	;;
esac


fi
	;;
	"以上操作仅对使用了spark-dwine-helper的应用生效")
	
	;;

	*)
	IS_CLOSE="1"
	;;


esac
done