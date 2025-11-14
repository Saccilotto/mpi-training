# Quick Start - Bubble Sort com Fases Paralelas

Guia rápido para compilar, testar e executar os experimentos do Trabalho 3.

## Passo 1: Compilação

### No Cluster Grad

```bash
cd bubble
./compile_grad.sh
```

### Localmente (se tiver MPI instalado)

```bash
cd bubble
make seq mpi-phases
```

## Passo 2: Teste Rápido

Valide a implementação com testes pequenos:

```bash
./test_phases.sh
```

**Esperado:** Todos os testes devem passar (✓).

## Passo 3: Experimentos Completos

Execute os experimentos com 1M elementos:

```bash
./run_phases_experiments.sh
```

**Importante no Grad:** Reserve os nós exclusivamente antes:

```bash
# Solicitar 2 nós exclusivos
salloc -N 2 --exclusive

# Depois execute o script
./run_phases_experiments.sh

# Ao terminar, libere os nós
exit
```

## Passo 4: Analisar Resultados

Os resultados estarão em `results_phases/`:

```bash
ls -lth results_phases/

# Ver relatório mais recente
cat results_phases/report_phases_*.txt | head -50

# Ver dados CSV
head -20 results_phases/phases_results_*.csv
```

## Passo 5: Preencher Relatório

```bash
# Copiar template
cp report_template.tex report_final.tex

# Editar com seus dados
nano report_final.tex  # ou vim, emacs, etc

# Compilar PDF
pdflatex report_final.tex
```

## Comandos Úteis

### Teste Manual Sequencial

```bash
# Pequeno (com debug)
./seq 40 1

# Grande (sem debug, para medição)
./seq 1000000 0
```

### Teste Manual Paralelo

```bash
# Local
mpirun -np 4 ./mpi_phases 40 1
mpirun -np 16 ./mpi_phases 1000000 0

# No Grad
srun -N 2 -n 16 ./mpi_phases 1000000 0
srun -N 2 -n 32 ./mpi_phases 1000000 0
```

### Verificar Módulos no Grad

```bash
module list              # Ver módulos carregados
module avail             # Ver módulos disponíveis
module load openmpi      # Carregar OpenMPI
```

### Limpar Arquivos

```bash
make clean                    # Remove executáveis
rm -rf results_phases/        # Remove resultados
rm -f *.aux *.log *.pdf       # Remove arquivos LaTeX temporários
```

## Troubleshooting

### "mpicc not found"

```bash
module load openmpi
# ou
module load mpich
```

### "Tamanho deve ser divisível por np"

Use tamanhos que sejam múltiplos do número de processos:
- 16 processos: 1000000 ✓, 1000001 ✗
- 32 processos: 1000000 ✓, 1000010 ✗

### Teste muito lento

- Use `debug 0` (sem prints)
- Comece com tamanhos menores (10000)
- Bubble Sort é O(n²) - normal ser lento!

### Não consegue alocar nós no Grad

```bash
# Ver nós disponíveis
sinfo

# Ver sua fila
squeue -u $USER

# Cancelar jobs
scancel [job_id]
```

## Checklist de Entrega

- [ ] Código compila sem erros
- [ ] Testes de validação passam (test_phases.sh)
- [ ] Experimentos executados com 1M elementos
- [ ] Resultados coletados (CSV + relatório texto)
- [ ] Template LaTeX preenchido com dados reais
- [ ] PDF do relatório gerado (1 página, coluna dupla)
- [ ] Código comentado e claro
- [ ] Análise de desempenho escrita
- [ ] Comparação com divisão e conquista incluída
- [ ] Speedup e eficiência calculados
- [ ] Nome dos integrantes no relatório

## Recursos Adicionais

- **README completo:** `README_PHASES.md`
- **Documentação MPI:** https://www.open-mpi.org/doc/
- **Tutorial MPI:** https://mpitutorial.com/

## Contato

Dúvidas? Consulte o professor ou os monitores da disciplina.

---

**Boa sorte com o trabalho!** 🚀
