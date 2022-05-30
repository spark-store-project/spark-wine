#!/bin/bash

help() {
    cat <<EOF
用法：$0 [-h|--help] [-s|--set-scale-factor] path
-h|--help               显示这个帮助
-s|--set-scale-factor   直接指定缩放。支持1.0，1.25，1.5，2.0	
path                    容器目录


--------------------------------------------------------------------
Usage: $0 [-h|--help] [-s|--set-scale-factor] path
-h|--help               Show this text
-s|--set-scale-factor   Set scale factor direcly. Support 1.0，1.25，1.5，2.0	
path                    Wine Container directory path


EOF
}
#########################帮助文件结束#############################

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
        -h|--help)
            help
            exit
            ;;
	-s|--set-scale-factor)
	scale_factor="$2"
	;;
        *)
            CONTAINER_PATH="$1"

            ;;
    esac
    shift
    done
}
################
parse_args "$@"


#####先看看PATH对不对
if [ ! -f "$CONTAINER_PATH/user.reg" ];then
	echo "错误：找不到user.reg，退出。你应当在文件解压结束后调用此脚本"
    echo "E: Can not find user.reg. Exit. You should use this script after the extraction"
	exit 1
fi


if [ "$scale_factor" = "" ];then
#########未指定下
until [ "$env_dwine_scale" != "" ];do

env_dwine_scale=`echo $DEEPIN_WINE_SCALE`
if [ "$env_dwine_scale" = "" ];then
echo "E: No DEEPIN_WINE_SCALE found. Use spark-get-scale to Set "
echo "错误：没有检测到DEEPIN_WINE_SCALE，用spark-get-scale设置"
/opt/durapps/spark-dwine-helper/spark-get-scale.sh 
env_dwine_scale=`cat ~/.config/spark-wine/scale.txt`
echo "检测到的缩放倍数为:$env_dwine_scale"
echo "Scale is $env_dwine_scale"

else
echo "检测到的缩放倍数为:$env_dwine_scale"
echo "Scale is $env_dwine_scale"
fi

done
#####非deepin发行版似乎没有这个变量，暂时不清楚这个变量是哪个组件做的

else
#######指定了缩放倍数
echo "使用了--set-scale-factor，直接指定"
echo "--set-scale-factor detected. Arrange directly"


if [ "$scale_factor" != "1.0" ] && [ "$scale_factor" != "1.25" ] && [ "$scale_factor" != "1.5" ]  && [ "$scale_factor" != "2.0" ] ;then
echo "无法识别的倍数：$scale_factor，请参看$0 -h"
echo "Unrecognizable number. Use $0 -h to get help"
exit 1
fi
#######没问题了再用
env_dwine_scale=`echo $scale_factor`


fi

########开始设置
case "$env_dwine_scale" in
       1.0)
            reg_text="\"LogPixels\"=dword:00000060"
            ;;
        1.25)
            reg_text="\"LogPixels\"=dword:00000078"
            ;;
        1.5)
            reg_text="\"LogPixels\"=dword:00000090"
            ;;
        2.0)
            reg_text="\"LogPixels\"=dword:000000C0"
            ;;
	*)
		reg_text="\"LogPixels\"=dword:00000060"
		#可能不是Xorg
		;;
    esac

#####根据scale设置dword值


LogPixels_line=(`sed -n -e "/"LogPixels"/=" $CONTAINER_PATH/user.reg`)
#####关键词行数取得
until [ "${#LogPixels_line[@]}" = "0" ];do


line_num=${LogPixels_line[0]}

sed -i "$line_num"c\ "$reg_text" "$CONTAINER_PATH/user.reg"
LogPixels_line=(${LogPixels_line[@]:1})
done

echo "已经完成替换。位置：$CONTAINER_PATH/user.reg"
echo "在以下行数进行了替换，内容为$reg_text"
echo `sed -n -e "/"LogPixels"/=" $CONTAINER_PATH/user.reg`
echo "---------------------------------------"
