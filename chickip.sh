# /bin/bash
# chickip.sh

# 定义ip段,最多测到第三个字节！！！第四个字节不用写，两个定义一样就只测第四个字节
ip_start=104.20.26
ip_ending=104.20.120
# 定义并发的进程数,也就是每次ping的ip数
thread_num=20
# 定义每个ip ping的次数
time2=15
# 定义最大延迟
time1=160
# 定义最大丢包率
lost=5

###################################
# 新建一个FIFO类型的变量
myfifo="myfifo"
mkfifo ${myfifo}
# 将FD6指向FIFO类型
exec 6<>${myfifo}
rm -f ${myfifo}
# 在FD6中放置了$thread_num个占位信息
for ((i=0;i<=${thread_num};i++))
do
{
    echo 
}
done >&6

last_ping() {
    for ((ip_sub=1;ip_sub<=255;ip_sub++));
    do
        read -u6
        {   
           # 每个IP ping $time2次并获取每个IP的丢包率,延迟
            ping=`ping -c $time2 $ip_start.$ip_sub|grep -E 'loss|avg'`
            lose=`echo $ping|grep loss|awk '{print $6}'|awk -F "%" '{print $1}'|gawk -F . '{print $1}'`
            # 丢包率大于$lost丢弃
            if [ $lose -ge $lost ];then
                    echo "丢弃 $ip_start.$ip_sub 丢包率$lose"
            else
                    # 获取每个IP的延迟，丢弃延迟大于$time1的，延迟小于$time1的保存到chickip.log文件中
                    num=`echo $ping|grep avg | gawk -F / '{print $5}'|gawk -F . '{print $1}'`
                    if [ $num -ge $time1 ];then
                        echo "丢弃 $ip_start.$ip_sub 延迟 $num"
                    else
                        echo "保存 $ip_start.$ip_sub 延迟 $num 丢包率 $lose"
                        echo "$ip_start.$ip_sub 延迟:$num 丢包率 $lose" >> chickip.log
                    fi
            fi
            echo >&6 # 当进程结束以后，再向FD6中加上一个回车符，即补上了read -u6减去的那个
        } &
    done
}

if [ $ip_start = $ip_ending ];then
    last_ping
else
    for ((third=${ip_start##*.};third<=${ip_ending##*.};third++))
    do
    {
         ip_2="${ip_start%.*}.$third"
         rm -f $ip_start
         ip_start=$ip_2
         last_ping
    }
    done
fi

# 等待所有线程结束，删掉wait会后台运行
wait

# 关闭fd6管道
exec 6>&-
