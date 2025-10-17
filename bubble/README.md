# Bubble Sort Paralelo - MPI

Implementação paralela do algoritmo Bubble Sort usando MPI com estratégia de divisão e conquista (divide-and-conquer).

## 📁 Estrutura do Projeto

```
bubble/
├── seq.c                   # Versão sequencial
├── mpi.c                   # Versão paralela MPI
├── Makefile                # Makefile para desenvolvimento local
├── Makefile.atlantica      # Makefile para cluster Atlantica
├── run_experiments.sh      # Script de experimentos automatizado
├── plot_results.gnuplot    # Script para geração de gráficos
├── README.md               # Este arquivo
└── results/                # Diretório para resultados (criado automaticamente)
```

## 🚀 Uso Rápido

### Local (Desenvolvimento)

```bash
# Compilar
make all

# Testar versão sequencial
make test-seq

# Testar versão MPI com 7 processos
make test-mpi NP=7

# Executar experimentos completos
./run_experiments.sh local

# Gerar gráficos
gnuplot plot_results.gnuplot
```

### Atlantica Cluster

```bash
# 1. SSH para o cluster
ssh pptmXX@atlantica.lad.pucrs.br

# 2. Clonar repositório
git clone <seu-repositorio>
cd bubble

# 3. Compilar
make -f Makefile.atlantica all

# 4. Teste rápido
make -f Makefile.atlantica test-mpi-small

# 5. Executar todos os experimentos
make -f Makefile.atlantica run-experiments

# 6. Copiar resultados para local (em outro terminal)
scp -r pptmXX@atlantica.lad.pucrs.br:~/bubble/results/ ./

# 7. Gerar gráficos localmente
gnuplot plot_results.gnuplot
```

## 📊 Arquivos de Dados Gerados

Após executar os experimentos, os seguintes arquivos são gerados em `results/`:

- `seq_TIMESTAMP.dat` - Tempos da versão sequencial
- `mpi_TIMESTAMP.dat` - Tempos, speedup e eficiência da versão MPI
- `times_by_size_TIMESTAMP.dat` - Comparação de tempos por tamanho
- `speedup_TIMESTAMP.dat` - Dados de speedup
- `efficiency_TIMESTAMP.dat` - Dados de eficiência

### Formato dos Arquivos

**seq_TIMESTAMP.dat:**

```
# Tamanho Tempo(s)
10000 0.254108
100000 25.410800
1000000 2541.080000
```

**mpi_TIMESTAMP.dat:**

```
# NP Tamanho Tempo(s) Speedup Eficiencia
3 10000 0.127054 2.0000 0.6667
7 10000 0.054301 4.6800 0.6686
15 10000 0.025410 10.0000 0.6667
```

## 📈 Gráficos Gerados

Após rodar `gnuplot plot_results.gnuplot`, os seguintes gráficos são gerados:

1. **grafico_tempos.png** - Tempo de execução vs tamanho do vetor
2. **grafico_speedup.png** - Speedup vs número de processos
3. **grafico_eficiencia.png** - Eficiência vs número de processos
4. **grafico_comparacao_1m.png** - Comparação para 1M elementos

## ⚙️ Parâmetros dos Programas

### Versão Sequencial (`seq`)

```bash
./seq [tamanho] [debug]
```

- `tamanho`: Número de elementos do vetor (padrão: 40)
- `debug`: 0 = desligado, 1 = ligado (padrão: 1)

**Exemplos:**
```bash
./seq 10000 0           # 10k elementos sem debug
./seq 1000000 0         # 1M elementos sem debug
```

### Versão MPI (`mpi`)

```bash
mpirun -np <processos> ./mpi [tamanho] [delta] [debug]
```

- `processos`: Número de processos MPI
- `tamanho`: Número de elementos do vetor (padrão: 40)
- `delta`: Tamanho mínimo para conquistar (padrão: 10, use 0 para automático)
- `debug`: 0 = desligado, 1 = ligado (padrão: 1)

**Exemplos:**

```bash
mpirun -np 7 ./mpi 10000 0 0      # 7 processos, 10k elementos, delta auto
mpirun -np 15 ./mpi 1000000 0 0   # 15 processos, 1M elementos, delta auto
```

## 🎯 Cálculo Automático de DELTA

O programa calcula automaticamente o valor ideal de DELTA quando passado como 0:

```
DELTA = array_size / 2^depth
onde depth = log2(num_processos)
```

**Exemplos:**

- 7 processos: depth = 2 → DELTA = size / 4
- 15 processos: depth = 3 → DELTA = size / 8

Isso garante que a árvore binária use todos os processos disponíveis sem tentar enviar para processos inexistentes.

## 🔧 Makefile - Targets Principais

### Local

```bash
make all                    # Compila tudo
make clean                  # Remove executáveis

make test-seq SIZE=1000     # Testa sequencial
make test-mpi NP=7 SIZE=1000 DELTA=0  # Testa MPI

make bench-seq-10k          # Benchmark sequencial 10k
make bench-mpi-10k          # Benchmark MPI 10k
make bench-all              # Todos os benchmarks

make verify                 # Verifica corretude
make speedup-analysis       # Análise de speedup

make help                   # Mostra ajuda completa
```

### Atlantica

```bash
make -f Makefile.atlantica all            # Compila tudo
make -f Makefile.atlantica clean          # Remove executáveis

make -f Makefile.atlantica test-mpi-small # Teste rápido
make -f Makefile.atlantica test-mpi-10k   # Teste 10k elementos

make -f Makefile.atlantica bench-atlantica  # Benchmark completo
make -f Makefile.atlantica run-experiments  # Experimentos completos

make -f Makefile.atlantica help           # Ajuda completa
```

## 🧪 Workflow de Experimentação

### 1. Desenvolvimento Local

```bash
# Compilar e testar
make all
make verify

# Teste com valores pequenos
make test-seq SIZE=100
make test-mpi NP=7 SIZE=100 DELTA=0
```

### 2. Experimentos Locais (Opcional)

```bash
# Executar experimentos locais para validar
./run_experiments.sh local

# Gerar gráficos
gnuplot plot_results.gnuplot

# Verificar gráficos em results/
ls -lh results/*.png
```

### 3. Commit e Push

```bash
git add .
git commit -m "feat: implementação completa com scripts de experimentação"
git push origin main
```

### 4. Executar na Atlantica

```bash
# SSH para Atlantica
ssh pptmXX@atlantica.lad.pucrs.br

# Clonar repositório
git clone <seu-repo-url>
cd bubble

# Executar experimentos
make -f Makefile.atlantica run-experiments

# Aguardar conclusão (pode demorar ~30-60 minutos para 1M elementos)
```

### 5. Recuperar Resultados

```bash
# Em outro terminal local
scp -r pptmXX@atlantica.lad.pucrs.br:~/bubble/results/ ./

# Commit dos dados
git add results/*.dat
git commit -m "data: resultados dos experimentos na Atlantica"
git push
```

### 6. Gerar Gráficos Localmente

```bash
# Gerar gráficos
gnuplot plot_results.gnuplot

# Verificar gráficos
ls -lh results/*.png

# Commit dos gráficos
git add results/*.png
git commit -m "docs: gráficos dos experimentos"
git push
```

## 📐 Cálculos de Métricas

### Speedup

```
Speedup = T_sequencial / T_paralelo
```

**Exemplo:**

- T_seq = 100s
- T_mpi(7 proc) = 20s
- Speedup = 100 / 20 = 5x

### Eficiência

```
Eficiência = Speedup / Número_de_Processos
```

**Exemplo:**

- Speedup = 5x
- Processos = 7
- Eficiência = 5 / 7 = 0.714 (71.4%)

### Speedup Ideal

```
Speedup_ideal = Número_de_Processos
```

No gráfico, a linha pontilhada representa o speedup ideal (linear).

## 🐛 Troubleshooting

### Erro: "MPI_ERR_RANK: invalid rank"

**Causa:** DELTA muito pequeno, tentando enviar para processos inexistentes.

**Solução:** Use DELTA=0 (automático) ou aumente o valor de DELTA.

### Erro: "ladcomp: command not found" (Atlantica)

**Causa:** Não está na máquina hospedeira correta.

**Solução:** Certifique-se de que está logado em `atlantica.lad.pucrs.br`.

### Experimentos muito lentos

**Causa:** Bubble Sort é O(n²), muito lento para vetores grandes.

**Dica:** Para testes rápidos, use tamanhos menores (10k, 100k) primeiro.

## 📝 Para o Relatório

Os dados gerados pelos experimentos podem ser usados para:

1. **Tabela de Tempos** - Use `results/*_TIMESTAMP.dat`
2. **Gráfico de Speedup** - `results/grafico_speedup.png`
3. **Gráfico de Eficiência** - `results/grafico_eficiencia.png`
4. **Análise de Balanceamento** - Compare tempos dos diferentes níveis da árvore (logs de debug)
5. **Ganho com HT** - Compare execuções com/sem hyperthreading na Atlantica

## 🎓 Autores

Grupo pptm03 - Programação Paralela e Distribuída

## 📄 Licença

MIT License - Trabalho acadêmico PUCRS
