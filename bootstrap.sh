#!/bin/bash

echo "===== INICIANDO SCRIPT DE BOOTSTRAP DO HADOOP-MASTER ====="

# 1. Inicia o SSH local
service ssh start
rm -f /root/.ssh/known_hosts

# 2. Corrige arquivos de configuração (Necessário se estiver usando Volumes do Windows)
echo "Aplicando correções de configuração para formato Linux..."
echo -e "hadoop-worker-1\nhadoop-worker-2" > $HADOOP_HOME/etc/hadoop/workers
sed -i 's/\r$//' $HADOOP_HOME/etc/hadoop/hadoop-env.sh 2>/dev/null || true
sed -i 's/\r$//' $HADOOP_HOME/etc/hadoop/yarn-site.xml 2>/dev/null || true
sed -i 's/\r$//' $HADOOP_HOME/etc/hadoop/core-site.xml 2>/dev/null || true
sed -i 's/\r$//' $HADOOP_HOME/etc/hadoop/hdfs-site.xml 2>/dev/null || true
sed -i 's/\r$//' $HADOOP_HOME/etc/hadoop/mapred-site.xml 2>/dev/null || true
sed -i 's/\r$//' $HADOOP_HOME/etc/hadoop/capacity-scheduler.xml 2>/dev/null || true


# 3. Aguarda os Workers estarem prontos via SSH
echo "Aguardando conexão SSH com os workers..."
until ssh -o StrictHostKeyChecking=no hadoop-worker-1 "exit" >/dev/null 2>&1; do
  echo "Worker 1 ainda não está pronto... dormindo 5s"
  sleep 5
done

until ssh -o StrictHostKeyChecking=no hadoop-worker-2 "exit" >/dev/null 2>&1; do
  echo "Worker 2 ainda não está pronto... dormindo 5s"
  sleep 5
done
echo "Conexão com Workers estabelecida!"

# 4. Formata e Inicia o Hadoop
echo "Formatando NameNode..."
$HADOOP_HOME/bin/hdfs namenode -format -force

echo "Iniciando HDFS..."
$HADOOP_HOME/sbin/start-dfs.sh

echo "Iniciando YARN..."
$HADOOP_HOME/sbin/start-yarn.sh

# 5. Prepara o Ambiente do Job (só se a pasta não existir)
if ! $HADOOP_HOME/bin/hdfs dfs -test -d /user/niajus/input; then
  echo "Pasta /user/niajus/input não encontrada. Criando e populando..."
  $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/niajus/input
  $HADOOP_HOME/bin/hdfs dfs -put /root/textos/*.txt /user/niajus/input/
else
  echo "Pasta /user/niajus/input já existe."
fi

# Garante permissão de execução nos scripts
chmod +x /root/scripts/mapper.py 2>/dev/null || true
chmod +x /root/scripts/reducer.py 2>/dev/null || true

echo ""
echo "================================================="
echo "O CLUSTER HADOOP ESTÁ PRONTO E ON-LINE."
echo "Acesse as UIs:"
echo "HDFS (NameNode):   http://localhost:9870"
echo "YARN (Cluster):    http://localhost:8088"
echo ""
echo "Para rodar o job, acesse o mestre com:"
echo "docker exec -it meu-lab-hadoop-hadoop-master-1 /bin/bash"
echo "================================================="

# 6. Mantém o container rodando
tail -f /dev/null