#!/usr/bin/env python3
"""
Executa o experimento de tuning a partir dos arquivos SQL do projeto.
- Não contém consultas SQL de negócio hardcoded: lê os arquivos .sql.
- Mede EXPLAIN ANALYZE em 03 e 05, com repetições e mediana.
- Gera relatório HTML e JSON com comandos, planos e tempos.
"""
from __future__ import annotations

import argparse
import getpass
import html
import json
import statistics
import sys
from datetime import datetime
from pathlib import Path

import psycopg2
import sqlparse
from psycopg2.extras import RealDictCursor

ROOT = Path(__file__).resolve().parent
SQL_DIR = ROOT
MEASURE_FILES = {"03_medicao_antes.sql", "05_medicao_depois.sql"}

def read_sql(filename: str) -> str:
    path = SQL_DIR / filename
    if not path.exists():
        raise FileNotFoundError(f"Arquivo SQL não encontrado: {path}")
    return path.read_text(encoding="utf-8-sig")

def split_statements(source: str):
    r"""Divide SQL respeitando strings e comentários; ignora metacomandos do psql."""
    cleaned = []
    for line in source.splitlines():
        if line.lstrip().startswith("\\"):
            continue
        cleaned.append(line)
    statements = []
    for raw in sqlparse.split("\n".join(cleaned)):
        # Remove comentários SQL. Alguns arquivos terminam com comentários
        # explicativos; eles não devem ser enviados ao PostgreSQL como consultas.
        statement = sqlparse.format(raw, strip_comments=True).strip()
        # Também descarta fragmentos formados apenas por ponto e vírgula.
        if statement and statement.strip().strip(";").strip():
            statements.append(statement)
    return statements

def is_explain(stmt: str) -> bool:
    return stmt.lstrip().upper().startswith("EXPLAIN")

def run_plain_file(conn, filename: str, log: list):
    source = read_sql(filename)
    with conn.cursor() as cur:
        for stmt in split_statements(source):
            if not stmt.strip().strip(";").strip():
                continue
            cur.execute(stmt)
            log.append({"arquivo": filename, "sql": stmt, "status": "executado"})
            # Registra resultados tabulares úteis sem exigir que todo SELECT tenha retorno.
            if cur.description:
                rows = cur.fetchall()
                log[-1]["linhas_retornadas"] = len(rows)
                if rows and len(rows) <= 30:
                    log[-1]["resultado"] = [
                        [str(v) if v is not None else None for v in row] for row in rows
                    ]
    conn.commit()

def run_measurement_file(conn, filename: str, repeats: int, log: list, measurements: list):
    source = read_sql(filename)
    stage = "ANTES" if "antes" in filename else "DEPOIS"
    query_number = 0
    with conn.cursor() as cur:
        for stmt in split_statements(source):
            if not stmt.strip().strip(";").strip():
                continue
            upper = stmt.lstrip().upper()
            if upper.startswith("SET ") or upper.startswith("RESET "):
                cur.execute(stmt)
                log.append({"arquivo": filename, "sql": stmt, "status": "executado"})
                continue
            if not is_explain(stmt):
                # Executa comandos auxiliares do arquivo (ex.: aquecimento).
                cur.execute(stmt)
                if cur.description:
                    cur.fetchall()
                log.append({"arquivo": filename, "sql": stmt, "status": "executado"})
                continue

            # EXPLAIN ANALYZE executado N vezes; JSON permite extrair o tempo real.
            query_number += 1
            explain_sql = stmt.rstrip().rstrip(";")
            json_sql = explain_sql.replace(
                "EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)",
                "EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, FORMAT JSON)",
                1
            )
            times, plans = [], []
            for attempt in range(1, repeats + 1):
                cur.execute(json_sql)
                raw = cur.fetchone()[0]
                plan = raw[0] if isinstance(raw, list) else raw
                root = plan.get("Plan", {})
                execution_ms = plan.get("Execution Time")
                planning_ms = plan.get("Planning Time")
                times.append(float(execution_ms))
                plans.append(plan)
                measurements.append({
                    "etapa": stage,
                    "arquivo": filename,
                    "consulta": query_number,
                    "repeticao": attempt,
                    "planning_ms": planning_ms,
                    "execution_ms": execution_ms,
                    "shared_hit_blocks": root.get("Shared Hit Blocks"),
                    "shared_read_blocks": root.get("Shared Read Blocks"),
                    "temp_read_blocks": root.get("Temp Read Blocks"),
                    "temp_written_blocks": root.get("Temp Written Blocks"),
                    "plano": plan
                })
            median = statistics.median(times)
            log.append({
                "arquivo": filename, "sql": stmt, "status": f"medido {repeats} vezes",
                "tempos_ms": times, "mediana_ms": median
            })
    conn.commit()

def build_reports(log, measurements, args):
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    json_path = ROOT / f"resultado_tuning_{stamp}.json"
    html_path = ROOT / f"relatorio_tuning_{stamp}.html"

    # Agrupa medições por etapa/consulta e calcula mediana.
    groups = {}
    for item in measurements:
        key = (item["etapa"], item["consulta"])
        groups.setdefault(key, []).append(item["execution_ms"])
    summary = [
        {"etapa": etapa, "consulta": consulta, "repeticoes": len(vals),
         "mediana_ms": statistics.median(vals), "min_ms": min(vals), "max_ms": max(vals)}
        for (etapa, consulta), vals in sorted(groups.items())
    ]
    payload = {
        "gerado_em": datetime.now().isoformat(timespec="seconds"),
        "conexao": {"host": args.host, "port": args.port, "database": args.database, "user": args.user},
        "repeticoes": args.repeats,
        "resumo": summary,
        "execucao_sql": log,
        "medicoes_detalhadas": measurements,
    }
    json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2, default=str), encoding="utf-8")

    rows = "".join(
        f"<tr><td>{html.escape(x['etapa'])}</td><td>{x['consulta']}</td>"
        f"<td>{x['repeticoes']}</td><td>{x['mediana_ms']:.3f}</td>"
        f"<td>{x['min_ms']:.3f}</td><td>{x['max_ms']:.3f}</td></tr>"
        for x in summary
    )
    command_sections = []
    for i, item in enumerate(log, 1):
        command_sections.append(
            f"<details><summary>{i}. {html.escape(item['arquivo'])} — {html.escape(item['status'])}</summary>"
            f"<pre>{html.escape(item['sql'])}</pre>"
            f"<p>Tempos (ms): {html.escape(str(item.get('tempos_ms', [])))} | "
            f"Mediana: {html.escape(str(item.get('mediana_ms', '—')))}</p></details>"
        )
    html_doc = f"""<!doctype html><html lang="pt-br"><meta charset="utf-8">
<title>Relatório de Tuning PostgreSQL</title>
<style>body{{font:15px Arial;margin:32px;color:#202938}}table{{border-collapse:collapse;width:100%}}
td,th{{border:1px solid #ccd2da;padding:9px;text-align:left}}th{{background:#eef2f7}}
pre{{white-space:pre-wrap;background:#f4f6f8;padding:12px}}details{{margin:12px 0}}</style>
<h1>Relatório de Tuning PostgreSQL</h1>
<p>Banco: {html.escape(args.database)} | Host: {html.escape(args.host)} |
Repetições por consulta: {args.repeats}</p>
<h2>Resumo — mediana do Execution Time</h2>
<table><tr><th>Etapa</th><th>Consulta</th><th>Repetições</th>
<th>Mediana (ms)</th><th>Mínimo (ms)</th><th>Máximo (ms)</th></tr>{rows}</table>
<h2>Comandos SQL executados</h2>{''.join(command_sections)}
<p>Os planos completos, buffers e configurações estão no arquivo JSON associado.</p>
</html>"""
    html_path.write_text(html_doc, encoding="utf-8")
    return html_path, json_path

def main():
    parser = argparse.ArgumentParser(description="Auditoria de tuning PostgreSQL baseada nos arquivos SQL.")
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", default="5432")
    parser.add_argument("--database", default="tuning_vendas")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--password", default=None)
    parser.add_argument("--repeats", type=int, default=5)
    parser.add_argument("--setup", action="store_true",
                        help="Executa 00_criar_banco.sql (APAGA as tabelas existentes do schema loja).")
    parser.add_argument("--confirm-reset", action="store_true",
                        help="Confirma a operação destrutiva do --setup.")
    parser.add_argument("--load-data", action="store_true",
                        help="Executa 01_popular_dados.sql (insere os dados de demonstração).")
    parser.add_argument("--skip-before", action="store_true")
    parser.add_argument("--skip-after", action="store_true")
    args = parser.parse_args()

    if args.repeats < 1:
        parser.error("--repeats deve ser pelo menos 1.")
    if args.setup and not args.confirm_reset:
        parser.error("--setup é destrutivo. Para confirmar, acrescente --confirm-reset.")
    if args.setup and args.load_data is False:
        print("Aviso: --setup cria as tabelas, mas não popula os dados. Use também --load-data.")

    password = args.password if args.password is not None else getpass.getpass("Senha do PostgreSQL: ")
    conn = None
    log, measurements = [], []
    try:
        conn = psycopg2.connect(
            host=args.host, port=args.port, dbname=args.database,
            user=args.user, password=password
        )
        conn.autocommit = False
        print(f"Conectado ao banco {args.database} como {args.user}.")

        if args.setup:
            print("Executando estrutura (00_criar_banco.sql)...")
            run_plain_file(conn, "00_criar_banco.sql", log)
        if args.load_data:
            print("Carregando dados (01_popular_dados.sql)...")
            run_plain_file(conn, "01_popular_dados.sql", log)

        if not args.skip_before:
            print(f"Medindo baseline ({args.repeats} repetições)...")
            run_measurement_file(conn, "03_medicao_antes.sql", args.repeats, log, measurements)

        print("Aplicando índices e tuning (04_aplicar_tuning.sql)...")
        run_plain_file(conn, "04_aplicar_tuning.sql", log)

        if not args.skip_after:
            print(f"Medindo depois do tuning ({args.repeats} repetições)...")
            run_measurement_file(conn, "05_medicao_depois.sql", args.repeats, log, measurements)

        print("Executando validação e manutenção (06_validacao_e_manutencao.sql)...")
        run_plain_file(conn, "06_validacao_e_manutencao.sql", log)

        html_file, json_file = build_reports(log, measurements, args)
        print("\nExecução concluída.")
        print(f"Relatório HTML: {html_file}")
        print(f"Dados completos JSON: {json_file}")
    except Exception as exc:
        if conn:
            conn.rollback()
        print(f"\nERRO: {exc}", file=sys.stderr)
        print("Verifique o arquivo SQL, permissões do usuário e se o banco/tabelas existem.", file=sys.stderr)
        raise
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
