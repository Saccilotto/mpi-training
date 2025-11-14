# Bubble Sort Paralelo - Modelo de Fases Paralelas

Este diretório contém a implementação do algoritmo Bubble Sort usando o modelo de **Fases Paralelas** com MPI, conforme especificação do Trabalho 3.

## Estrutura de Arquivos

```
bubble/
├── seq.c                          # Versão sequencial do Bubble Sort
├── mpi_bubblesort_phases.c        # Versão paralela com Fases Paralelas
├── mpi_bubblesort.c               # Versão paralela com Divisão e Conquista (comparação)
├── Makefile                       # Makefile para compilação
├── run_phases_experiments.sh      # Script de execução dos experimentos
├── report_template.tex            # Template do relatório em LaTeX
└── README_PHASES.md              # Este arquivo
```

## Compilação

### Ambiente Local (sem MPI)

```bash
make seq
```

### Cluster Grad (com MPI/OpenMPI)

```bash
# Compilar todas as versões
make all

# Ou compilar apenas as necessárias
make seq
make mpi-phases
```

## Execução

### Versão Sequencial

```bash
./seq [tamanho] [debug]

# Exemplos:
./seq 40 1                    # 40 elementos com debug
./seq 1000000 0               # 1M elementos sem debug (medição)
```

### Versão Paralela (Fases Paralelas)

```bash
mpirun -np [num_processos] ./mpi_phases [tamanho] [debug]

# Exemplos:
mpirun -np 4 ./mpi_phases 40 1          # 4 processos, 40 elementos, com debug
mpirun -np 16 ./mpi_phases 1000000 0    # 16 processos, 1M elementos, sem debug
```

### No Cluster Grad (usando srun)

```bash
srun --exclusive -N 2 -n 16 ./mpi_phases 1000000 0
srun --exclusive -N 2 -n 32 ./mpi_phases 1000000 0
```

## Experimentos Automatizados

O script `run_phases_experiments.sh` executa automaticamente todos os experimentos necessários:

```bash
./run_phases_experiments.sh
```

Este script:
1. Executa a versão sequencial
2. Executa a versão paralela com 4, 8, 16 e 32 processos
3. Calcula speedup e eficiência
4. Compara com o modelo de divisão e conquista (se disponível)
5. Gera arquivo CSV com resultados
6. Gera relatório em texto

### Resultados

Os resultados são salvos em:
- `results_phases/phases_results_[timestamp].csv` - Dados em CSV
- `results_phases/report_phases_[timestamp].txt` - Relatório em texto

## Algoritmo - Fases Paralelas

O modelo de fases paralelas funciona da seguinte forma:

### Inicialização
- Cada processo gera 1/np do vetor global em ordem decrescente
- Processo 0 tem os valores mais altos, processo np-1 tem os mais baixos

### Loop Principal (até convergência)

#### Fase 1: Ordenação Local
- Cada processo ordena seu subvetor localmente usando Bubble Sort

#### Fase 2: Verificação Distribuída
- Cada processo envia seu maior valor para o vizinho à direita
- Cada processo recebe o maior valor do vizinho à esquerda
- Compara seu menor valor com o maior valor recebido
- Usa `MPI_Allreduce` para verificar se todos estão ordenados

#### Fase 3: Troca de Valores (se necessário)
- Processos trocam valores com vizinhos para empurrar valores fora de lugar
- Processo i envia menores valores para i-1
- Processo i-1 intercala e devolve maiores valores
- Cada processo mantém apenas os valores corretos

## Parâmetros de Configuração

### Tamanho do Vetor
- **Importante:** O tamanho do vetor deve ser divisível pelo número de processos
- Para 16 processos: múltiplos de 16 (ex: 1.000.000)
- Para 32 processos: múltiplos de 32 (ex: 1.000.000)

### Número de Processos
- Recomendado para o Grad (2 nós):
  - 4, 8, 16 processos (sem HT)
  - 4, 8, 16, 32 processos (com HT)

## Análise de Desempenho

### Métricas Calculadas

1. **Speedup:** S_p = T_seq / T_par
2. **Eficiência:** E_p = (S_p / p) × 100%
3. **Número de Iterações:** Quantas iterações até convergência

### Fatores que Afetam o Desempenho

- **Overhead de comunicação:** MPI_Send/Recv a cada iteração
- **Sincronização global:** MPI_Allreduce a cada iteração
- **Número de iterações:** Depende da distribuição inicial
- **Balanceamento de carga:** Uniforme (1/np por processo)

## Comparação com Divisão e Conquista

### Fases Paralelas
- ✓ Distribuição uniforme de dados
- ✓ Padrão de comunicação regular
- ✗ Múltiplas iterações
- ✗ Overhead de verificação global

### Divisão e Conquista
- ✓ Única passagem pelos dados
- ✓ Menos sincronizações
- ✗ Desbalanceamento possível
- ✗ Intercalação pode ser custosa

## Relatório

### Compilar o Relatório (LaTeX)

```bash
cd bubble
pdflatex report_template.tex
```

### Preencher o Template

1. Copie `report_template.tex` para `report_[seu_nome].tex`
2. Edite o arquivo e preencha:
   - Nomes e e-mails dos integrantes
   - Dados da Tabela 1 com seus resultados experimentais
   - Análise de desempenho na Seção 3.2
   - Dados da Tabela 2 com comparação
   - Análise comparativa na Seção 4
   - Conclusões na Seção 5
3. Compile com `pdflatex`

## Troubleshooting

### Erro: "Tamanho deve ser divisível pelo número de processos"

Solução: Use tamanhos que sejam múltiplos do número de processos.

```bash
# Correto
mpirun -np 16 ./mpi_phases 1000000 0  # 1000000 % 16 = 0

# Incorreto
mpirun -np 16 ./mpi_phases 1000001 0  # 1000001 % 16 ≠ 0
```

### Erro: "mpicc: command not found"

Solução: Carregue o módulo MPI no cluster:

```bash
module load openmpi
# ou
module load mpich
```

### Experimento muito lento

- Verifique se está usando debug=0
- Para testes rápidos, use tamanhos menores (ex: 10000)
- Bubble Sort tem complexidade O(n²) - vetores grandes são lentos!

## Dicas de Otimização

### Para Reduzir Tempo de Execução

1. **Desabilite debug:** Use sempre debug=0 nas medições
2. **Use flags de otimização:** `-O2` ou `-O3` no Makefile
3. **Evite prints:** Não use printf dentro dos loops principais

### Para Melhorar Escalabilidade

1. **Minimize comunicação:** Reduzir número de iterações
2. **Use comunicação assíncrona:** MPI_Isend/Irecv (avançado)
3. **Otimize ordenação local:** Use algoritmos mais eficientes

## Referências

- MPI Tutorial: https://mpitutorial.com/
- OpenMPI Documentation: https://www.open-mpi.org/doc/
- Documentação do cluster Grad: [consulte seu professor/TA]

## Autores

[Seu Nome] - [Seu Email]
[Nome do Parceiro] - [Email do Parceiro]

## Data

[Data de Entrega]
