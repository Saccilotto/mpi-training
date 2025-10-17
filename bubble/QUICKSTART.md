# 🚀 GUIA RÁPIDO - Bubble Sort Paralelo MPI

## ✅ O Que Você Tem Agora

### 📄 Arquivos de Código

- `seq.c` - Versão sequencial com argumentos CLI
- `mpi.c` - Versão paralela MPI com DELTA automático

### 🔧 Build & Automação

- `Makefile` - 30+ targets para desenvolvimento local
- `Makefile.atlantica` - Adaptado para cluster Atlantica  
- `run_experiments.sh` - Script de experimentos completo
- `plot_results.gnuplot` - Geração automática de gráficos

### 📚 Documentação

- `README.md` - Documentação completa
- `QUICKSTART.md` - Este guia (você está aqui!)

---

## 🎯 CHECKLIST PARA O TRABALHO

### ✅ Fase 1: Validação Local (FEITO!)

- [x] Versão sequencial funcional
- [x] Versão MPI funcional  
- [x] DELTA automático implementado
- [x] Makefile completo
- [x] Scripts de experimentos prontos

### 🔄 Fase 2: Experimentos na Atlantica (PRÓXIMO PASSO!)

```bash
# 1. Fazer push do código
git add .
git commit -m "feat: implementação completa com infraestrutura de testes"
git push

# 2. SSH para Atlantica
ssh pptmXX@atlantica.lad.pucrs.br

# 3. Clonar e executar
git clone <seu-repo>
cd bubble
make -f Makefile.atlantica run-experiments

# 4. Aguardar (~30-60min para 1M elementos)

# 5. Copiar resultados (em outro terminal local)
scp -r pptmXX@atlantica.lad.pucrs.br:~/bubble/results/ ./
```

### 📊 Fase 3: Análise e Relatório

```bash
# 1. Gerar gráficos
gnuplot plot_results.gnuplot

# 2. Visualizar
ls -lh results/*.png

# 3. Calcular métricas
# - Speedup = T_seq / T_mpi
# - Eficiência = Speedup / NP
# - Ver README.md para fórmulas completas
```

---

## ⚡ COMANDOS MAIS USADOS

### Desenvolvimento Local

```bash
# Compilar tudo
make all

# Testar rapidamente
make test-seq SIZE=1000 DEBUG=0
make test-mpi NP=7 SIZE=1000 DELTA=0 DEBUG=0

# Verificar corretude
make verify

# Benchmarks
make bench-seq-10k
make bench-mpi-10k

# Experimentos completos (DEMORADO!)
./run_experiments.sh local
```

### Na Atlantica

```bash
# Compilar
make -f Makefile.atlantica all

# Teste rápido
make -f Makefile.atlantica test-mpi-small

# Experimentos completos
make -f Makefile.atlantica run-experiments

# Benchmark específico
make -f Makefile.atlantica bench-atlantica
```

---

## 💡 DICAS IMPORTANTES

### 1. DELTA Automático

✅ **Use sempre DELTA=0** (automático) a não ser que o enunciado especifique outro valor.

```bash
# Automático (recomendado)
mpirun -np 7 ./mpi 10000 0 0

# Manual (apenas se necessário)
mpirun -np 7 ./mpi 10000 1250 0
```

### 2. Número de Processos

- **3 processos**: usa 1 nível da árvore (1 raiz + 2 filhos)
- **7 processos**: usa 2 níveis (árvore completa)
- **15 processos**: usa 3 níveis (para 2 nós na Atlantica)

### 3. Tamanhos de Teste

- **40**: teste rápido com debug
- **10.000**: benchmark pequeno (~0.2s sequencial)
- **100.000**: benchmark médio (~25s sequencial)
- **1.000.000**: benchmark completo (~2500s = 42min sequencial!)

### 4. Debug ON vs OFF

```bash
# Debug ON (mostra toda a comunicação MPI)
mpirun -np 7 ./mpi 40 10 1

# Debug OFF (apenas tempo de execução)
mpirun -np 7 ./mpi 10000 0 0
```

---

## 📊 DADOS PARA O RELATÓRIO

Após rodar os experimentos, você terá:

### Tabelas

- `results/seq_*.dat` → Tempos sequenciais
- `results/mpi_*.dat` → Tempos MPI + Speedup + Eficiência

### Gráficos

- `results/grafico_tempos.png` → Comparação de tempos
- `results/grafico_speedup.png` → Análise de speedup
- `results/grafico_eficiencia.png` → Análise de eficiência

### Métricas para Análise

- ✅ Speedup obtido (ideal vs real)
- ✅ Eficiência por número de processos
- ✅ Balanceamento de carga (ver logs de debug)
- ✅ Overhead de comunicação MPI
- ✅ Ganho com hyperthreading (comparar 8 vs 16 cores/nó)

---

## 🐛 PROBLEMAS COMUNS

### "MPI_ERR_RANK: invalid rank"

→ DELTA muito pequeno. Use DELTA=0 (automático).

### "ladcomp: command not found"

→ Você não está na Atlantica. SSH primeiro.

### Experimentos muito lentos

→ Normal! Bubble Sort é O(n²). Para 1M elementos, pode levar 30-60min.

### GNUplot não encontra arquivos

→ Certifique-se que os arquivos .dat estão em `results/`.

---

## ✨ PRÓXIMOS PASSOS

1. ✅ **Commit tudo para o Git**

   ```bash
   git add .
   git commit -m "feat: implementação completa"
   git push
   ```

2. 🚀 **Executar na Atlantica**
   - SSH para atlantica.lad.pucrs.br
   - Clonar repositório
   - Executar experimentos

3. 📊 **Gerar gráficos localmente**
   - Copiar results/ da Atlantica
   - Rodar gnuplot
   - Commit dos dados e gráficos

4. 📝 **Escrever relatório**
   - Usar templates fornecidos no Moodle
   - Incluir gráficos gerados
   - Análise de speedup, eficiência, balanceamento

---
