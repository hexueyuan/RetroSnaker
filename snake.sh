#!/bin/bash

declare -r title="Retro Snaker v1.0.coding by hexueyuan"
declare -r info="Use w/s/a/d to control the snake."

#screen size
#20*10
declare -r screenWidth=22
declare -r screenHeight=12
#为了后边使用方便计算出来的经常使用的值
declare -i down=$(expr ${screenHeight} - 1)
declare -i right=$(expr ${screenWidth} - 1)
declare -i width=$(expr ${down} - 1)
declare -i height=$(expr ${right} - 1)

#head tail and body
declare -i headX=2
declare -i headY=2
declare -i tailX=2
declare -i tailY=2
declare bodyX=(2)
declare bodyY=(2)
declare -i foodX=0
declare -i foodY=0

#direction
declare  direction="right"

#game status
declare  life="live"
declare  hasFood="no"
declare window=()

exec 3>debug

#数组的头部插入,删除操作，需要把尾部删除，并在头部插入新的值 
#在蛇移动时调用
##OK
function updateX()
{
    local len=${#bodyX[*]}

    local i=0
    for((i=$(expr ${len} - 1);i>0;i--))
    do
        bodyX[$i]=${bodyX[$(expr ${i} - 1)]}
    done
    bodyX[0]=${1}
}

##OK
function updateY()
{
    local len=${#bodyY[*]}

    local i=0
    for((i=$(expr ${len} - 1);i>0;i--))
    do
        bodyY[$i]=${bodyY[$(expr ${i} - 1)]}
    done
    bodyY[0]=${1}
}

#在数组前插入一个值，数组长度发生变化，在蛇吃到食物时调用
##OK
function addX()
{
    local len=${#bodyX[*]}

    local i=0
    for((i=${len};i>0;i--))
    do
        bodyX[${i}]=${bodyX[$(expr ${i} - 1)]}
    done
    bodyX[0]=${1}
}

##OK
function addY()
{
    local len=${#bodyY[*]}

    local i=0
    for((i=${len};i>0;i--))
    do
        bodyY[${i}]=${bodyY[$(expr ${i} - 1)]}
    done
    bodyY[0]=${1}
}

#生成一个空白窗口
##OK
function initWindow()
{
    local i=0
    local j=0
    for((i=0;i<${screenHeight};i++))
    do
        line=""
        for((j=0;j<${screenWidth};j++))
        do
            if [[ ${i} == 0 ]] || [[ ${i} == ${down} ]];then
                line="${line}-"
            elif [[ ${j} == 0 ]] || [[ ${j} == ${right} ]];then
                line="${line}|"
            else
                line="${line} "
            fi
        done
        window[${i}]="${line}"
    done
}

#根据window打印当前窗口
##OK
function printWindow()
{
    clear
    echo "${title}"
    echo "${info}"
    local i=0
    for((i=0;i<${screenHeight};i++));
    do
        echo "${window[${i}]}"
    done
}

#设置窗口上某个点的显示,只更新window不刷新屏幕
##OK
function setPoint()
{
    local x1=${1}
    local y1=${2}
    local ch=${3}

    if [ ${x1} -lt 1 ] || [ ${x1} -gt ${down} ];then
        echo 'Illegal  point:(' ${x1} "," ${y1} '),error X!' >&3
        return
    fi
    if [ ${y1} -lt 1 ] || [ ${x1} -gt ${right} ];then
        echo "Illegal  point:(" ${x1} "," ${y1} "),error Y!" >&3
        return
    fi

    local line=${window[${x1}]}
    local newline="${line:0:((y1-1))}${ch}${line:y1}"
    window[${x1}]="${newline}"
}

#取消窗口上某个点的显示,只更新window不刷新屏幕
##OK
function unsetPoint()
{
    setPoint ${1} ${2} " "
}

#在窗口里显示body，只能在initWindow后使用，避免覆盖
function setBody()
{
    if [[ ${#bodyX[*]} != ${#bodyY[*]} ]];then
        echo "${bodyX[*]}" >&3
        echo "${bodyY[*]}" >&3
        echo "body size is unsure." >&3
        return
    fi
    local len=${#bodyX[*]}
    local i=0
    local xt=0
    local yt=0
    for((i=0;i<${len};i++))
    do
        xt=${bodyX[${i}]}
        yt=${bodyY[${i}]}
        setPoint ${xt} ${yt} '*'
    done
}

#读取键盘输入
function readKey()
{
	read -d ' ' -sn 1 -t0.03
    case ${REPLY} in
        w) test ${direction} == "down" || direction="up";;
        s) test ${direction} == "up" || direction="down";;
        a) test ${direction} == "right" || direction="left";;
        d) test ${direction} == "left" || direction="right";;
    esac
}

#根据全局变量direction更新当前body
function updateWindow()
{
	unsetPoint ${tailX} ${tailY}
    if [[ ${direction} == "left" ]];then
        headY=$(expr ${headY} - 1)
    elif [[ ${direction} == "right" ]];then
        echo "i=" ${i} >&3
        headY=$(expr ${headY} + 1)
    elif [[ ${direction} == "up" ]];then
        headX=$(expr ${headX} - 1)
    else
        headX=$(expr ${headX} + 1)
    fi
    updateX ${headX}
    updateY ${headY}
    tailX=${bodyX[$(expr ${#bodyX[*]} - 1)]}
    tailY=${bodyY[$(expr ${#bodyY[*]} - 1)]}

    setPoint ${headX} ${headY} '*'
}

#随机生成食物，要求不在边界上，不在蛇身体上
#更新food状态，不刷新屏幕
#身体变长以后可能效率会很低
function produceFood()
{
    local len=${#bodyX[*]}
    local i=0
    local stat="no"
    while [[ ${stat} == "no" ]]
    do
        foodX=$(((RANDOM%9)+2))
        foodY=$(((RANDOM%19)+2))
        for((i=0;i<${len};i++))
        do
            if [[ ${foodX} != ${bodyX[${i}]} ]] && [[ ${foodY} != ${bodyY[${i}]} ]];then
                stat="yes"
            fi
        done
    done
    setPoint ${foodX} ${foodY} "o"
    echo "setFood at point:(" ${foodX} "," ${foodY} ")" >&3
    hasFood="yes"
}

#检查边界条件
function checkSide()
{
    if [[ ${direction} == "left" ]];then
        test ${headY} == 1 && life="die"
    elif [[ ${direction} == "right" ]];then
        test ${headY} == ${right} && life="die"
    elif [[ ${direction} == "up" ]];then
        test ${headX} == 1 && life="die"
    else
        test ${headX} == ${down} && life="die"
    fi
}

#检查身体碰撞
function checkBody()
{
    local len=${#bodyX[*]}
    local i=0
    for((i=5;i<len;i++))
    do
        if [[ ${headX} == ${bodyX[${i}]} ]] && [[ ${headY} == ${bodyY[${i}]} ]];then
            life="die"
        fi
    done
}

#检查食物状态
function checkFood()
{
    local nextX=${headX}
    local nextY=${headY}
	if [[ ${direction} == "left" ]];then
        nextY=$(expr ${headY} - 1)
    elif [[ ${direction} == "right" ]];then
        nextY=$(expr ${headY} + 1)
    elif [[ ${direction} == "up" ]];then
        nextX=$(expr ${headX} - 1)
    else
        nextX=$(expr ${headX} + 1)
    fi

    if [[ ${nextX} == ${foodX} ]] && [[ ${nextY} == ${foodY} ]];then
        hasFood="no"
    fi
}

#更新游戏状态
function checkStatus()
{
    checkSide
    checkBody
}

#根据游戏状态决定是否更新食物，同时修改蛇身体长度
function updateFood()
{
    if [[ ${hasFood} == "no" ]];then
        echo "setFood at point:(" ${foodX} "," ${foodY} ")" >&3
        headX=${foodX}
        headY=${foodY}
        addX ${headX}
        addY ${headY}
        setPoint ${headX} ${headY} "*"
        produceFood
    fi
}

function main()
{
    initWindow
    setBody
    produceFood
    printWindow
    while [[ ${life} == "live" ]];
    do
        readKey
        checkFood
        updateFood
        updateWindow
        checkStatus
        printWindow
        echo "body length:" ${#bodyY[*]} >&3
        echo "head:(" ${headX} "," ${headY} "),tail:(" ${tailX} "," ${tailY} ")" >&3 
        sleep 0.3
    done
    echo "Game over!"
}

main
