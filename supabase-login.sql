-- =====================================================================
-- DIÁRIO FIT — segurança por usuário (rodar no SQL Editor do Supabase)
-- =====================================================================

-- ---------- PASSO 1: rodar agora, antes de criar as contas ----------

-- cada linha passa a ter um dono
alter table public.diario_kv add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.diario_kv alter column user_id set default auth.uid();
create index if not exists diario_kv_user_id_idx on public.diario_kv (user_id);

-- remove as regras antigas (que deixavam qualquer um ler e gravar)
do $$
declare r record;
begin
  for r in select policyname from pg_policies where schemaname = 'public' and tablename = 'diario_kv' loop
    execute format('drop policy %I on public.diario_kv', r.policyname);
  end loop;
end $$;

alter table public.diario_kv enable row level security;

-- cada pessoa só vê e mexe nos próprios dados.
-- "user_id is null" deixa ler os dados antigos (sem dono) só para a importação no 1º login.
create policy "le os proprios dados" on public.diario_kv
  for select to authenticated using (user_id = auth.uid() or user_id is null);
create policy "cria os proprios dados" on public.diario_kv
  for insert to authenticated with check (user_id = auth.uid());
create policy "altera os proprios dados" on public.diario_kv
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "apaga os proprios dados" on public.diario_kv
  for delete to authenticated using (user_id = auth.uid());


-- ---------- PASSO 2: rodar depois que todos importaram os dados antigos ----------
-- (descomente as linhas abaixo e rode)

-- delete from public.diario_kv where user_id is null;
-- drop policy "le os proprios dados" on public.diario_kv;
-- create policy "le os proprios dados" on public.diario_kv
--   for select to authenticated using (user_id = auth.uid());
