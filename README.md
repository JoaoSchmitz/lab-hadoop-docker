# Hadoop Cluster com Docker (1 Master, 2 Workers)

Este projeto sobe um cluster Hadoop completo usando Docker para fins de estudo e testes de MapReduce. O ambiente configura automaticamente o HDFS, o YARN e executa um job de exemplo.

## 📋 Pré-requisitos

- Docker e Docker Compose instalados.
- **Importante:** Devido ao tamanho, o instalador do Hadoop não está neste repositório.

## 🚀 Como Iniciar

### 1. Preparação

Antes de rodar, você precisa baixar o binário do Hadoop:

1.  Baixe o **Hadoop 3.3.6 (`hadoop-3.3.6.tar.gz`)**.
2.  Coloque o arquivo na **raiz** desta pasta (ao lado do `Dockerfile`).

A estrutura deve ficar assim:
```text
/
├── hadoop-configs/
├── scripts/
├── textos/
├── .gitignore
├── bootstrap.sh
├── docker-compose.yml
├── Dockerfile
├── hadoop-3.3.6.tar.gz <-- Arquivo baixado
└── README.md
```

### 2. Subir o Cluster

No terminal, execute:

```bash
docker compose up -d --build
```

Isso irá:

- Construir a imagem do cluster.
- Iniciar 3 contêineres (Master, Worker-1, Worker-2).
- Executar automaticamente o script `bootstrap.sh` que formata o HDFS e inicia os serviços.

### 3. Acompanhar a Inicialização

O cluster demora alguns segundos para ficar pronto. Você pode acompanhar o progresso vendo os logs do mestre:

```bash
docker logs -f meu-lab-hadoop-hadoop-master-1
```

Quando aparecer a mensagem **"O CLUSTER HADOOP ESTÁ PRONTO E ON-LINE"**, tudo terminou.

---

## 🐘 Interfaces Web

- **HDFS (NameNode):** [http://localhost:9870](http://localhost:9870)
- **YARN (Gerenciador de Recursos):** [http://localhost:8088](http://localhost:8088)

---

## 👨‍💻 Como rodar o Job (WordCount) Manualmente

O script de inicialização já roda o exemplo uma vez. Para rodar novamente ou testar suas alterações nos scripts Python:

1.  **Acesse o terminal do Nó Mestre:**
    ```bash
    docker exec -it meu-lab-hadoop-hadoop-master-1 /bin/bash
    ```

2.  **Prepare a saída (apague a anterior se existir):**
    ```bash
    hdfs dfs -rm -r /user/niajus/output
    ```

3.  **Execute o Job (Hadoop Streaming com Python):**
    ```bash
    hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar \
     -input /user/niajus/input \
     -output /user/niajus/output \
     -file /root/scripts/mapper.py \
     -mapper "python3 mapper.py" \
     -file /root/scripts/reducer.py \
     -reducer "python3 reducer.py"
    ```

4.  **Veja o resultado:**
    ```bash
    hdfs dfs -cat /user/niajus/output/part-00000
    ```

---

## 🛑 Como Parar e Limpar

Para desligar o cluster e **remover os dados/discos** (útil para resetar configurações):

```bash
docker-compose down -v
```
