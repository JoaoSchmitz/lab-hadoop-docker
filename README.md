# Hadoop Cluster com Docker (1 Master, 2 Workers)

Este projeto sobe um cluster Hadoop completo usando Docker para fins de estudo e testes de MapReduce.

## 📋 Pré-requisitos

- Docker e Docker Compose instalados.
- **Importante:** Devido ao tamanho, o instalador do Hadoop não está neste repositório.

## 🚀 Como Iniciar

### 1. Preparação

Antes de rodar, você precisa do binário do Hadoop (um arquivo de 700MB) na raiz do projeto.

Se você não tiver o arquivo baixado, execute o seguinte comando no seu terminal para realizar o download:

%%%bash
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz -O hadoop-3.3.6.tar.gz
%%%

*(Se `wget` não funcionar, você pode baixar o arquivo manualmente [deste link](https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz) e colocá-lo nesta pasta com o nome `hadoop-3.3.6.tar.gz`)*.

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

- Construir a imagem do cluster na primeira vez.
- Iniciar 3 contêineres (Master, Worker-1, Worker-2).
- Executar automaticamente o script `bootstrap.sh` que formata o HDFS, inicia os serviços e prepara os dados de teste.

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

O script `bootstrap.sh` já coloca os arquivos de texto no HDFS. Para rodar o job manualmente:

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

## 🧪 Testes de Tolerância a Falhas

Para executar esses testes, você precisará de um job que demore vários minutos.

### 1. Preparação: Gerar Dados de Teste

Primeiro, crie um arquivo grande (ex: 500MB) para que o job demore o suficiente.

1.  **Acesse o Mestre:**
    ```bash
    docker exec -it meu-lab-hadoop-hadoop-master-1 /bin/bash
    ```

2.  **(Dentro do mestre)** Crie e envie o arquivo para o HDFS:
    ```bash

    # Cria um arquivo de 500MB com dados aleatórios (demora um pouco)

    dd if=/dev/urandom of=/root/bigfile.txt bs=1M count=500

    # Envie-o para o HDFS (também demora um pouco)

    hdfs dfs -put /root/bigfile.txt /user/niajus/input/
    ```

### 2. Teste A (Baseline): Cluster Saudável

Rode o job no cluster saudável para marcar o tempo de execução.

1.  **(Dentro do mestre)** Limpe a saída e rode o job com `time`:
    ```bash
    hdfs dfs -rm -r /user/niajus/output

    time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar \
     -input /user/niajus/input/bigfile.txt \
     -output /user/niajus/output \
     -file /root/scripts/mapper.py \
     -mapper "python3 mapper.py" \
     -file /root/scripts/reducer.py \
     -reducer "python3 reducer.py"
    ```

2.  Anote o tempo `real` (ex: `real 3m15s`). Este é seu _baseline_.

### 3. Teste B: Falha de um Nó Escravo (Worker)

Aqui, vamos testar os dois tipos de falha de _worker_. Para ambos os casos, você precisará de **dois terminais locais** (fora do docker).

#### Como descobrir onde o "Cérebro" (ApplicationMaster) está:

1.  Inicie o job (Passo 2).
2.  Abra a UI do YARN (`http://localhost:8088`).
3.  Clique no ID da Aplicação (ex: `application_..._0001`).
4.  Role para baixo até "Application Attempts".
5.  A coluna **"Node"** mostrará qual _worker_ está rodando o "cérebro" (ex: `hadoop-worker-1`).

#### Cenário 1: Matar um Worker de TAREFA (Recuperação Rápida)

- **Objetivo:** Matar o _worker_ que **NÃO** está rodando o ApplicationMaster.

1.  No **Terminal 1 (Mestre)**: Inicie o job grande.
2.  Descubra qual nó roda o AM (ex: `worker-1`).
3.  No **Terminal 2 (Local)**: Mate o **outro** nó (ex: `worker-2`):
    ```bash
    docker stop meu-lab-hadoop-hadoop-worker-2-1
    ```
4.  **Resultado Esperado:** As tarefas em `worker-2` falharão (com `Connection reset by peer`). O AM (no `worker-1`) detectará isso **imediatamente** e reagendará as tarefas no `worker-1`. O job continua e termina com sucesso, mas mais devagar.

#### Cenário 2: Matar o ApplicationMaster (Recuperação Lenta)

- **Objetivo:** Matar o _worker_ que **ESTÁ** rodando o ApplicationMaster.

1.  No **Terminal 1 (Mestre)**: Inicie o job grande.
2.  Descubra qual nó roda o AM (ex: `worker-1`).
3.  No **Terminal 2 (Local)**: Mate **esse** nó:
    ```bash
    docker stop meu-lab-hadoop-hadoop-worker-1-1
    ```
4.  **Resultado Esperado:** O "cérebro" (AM) morre. O Mestre do Cluster (`:8088`) espera pelo _timeout_ (60 segundos). Após 60s, ele marca o `worker-1` como `LOST` e (graças à config `am.max-attempts`) lança uma **nova tentativa** do job (ex: `..._0002`) no `worker-2`. O job recomeça do zero e termina com sucesso.

### 4. Teste C: Falha do Nó Mestre (SPOF)

- **Objetivo:** Provar que o Mestre é um Ponto Único de Falha (SPOF).

1.  No **Terminal 1 (Mestre)**: Inicie o job grande.
2.  No **Terminal 2 (Local)**: Mate o contêiner mestre no meio da execução:
    ```bash
    docker stop meu-lab-hadoop-hadoop-master-1
    ```
3.  **Resultado Esperado:** **Falha catastrófica.** As UIs (`:8088` e `:9870`) morrem. O job no Terminal 1 para. Os _workers_ ficam órfãos. O job **não se recupera**.

---

## 🛑 Como Parar e Limpar

Para desligar o cluster e **remover os dados/discos** (obrigatório para resetar os testes):

```bash
docker compose down -v
```
