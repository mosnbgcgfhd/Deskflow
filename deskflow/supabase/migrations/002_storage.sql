-- =========================================================
-- DeskFlow — Storage bucket for Documents
-- =========================================================

-- Private bucket: files are only reachable via signed URLs
-- (DocumentService.getDownloadUrl), never a public link.
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

-- Files are stored at: {organization_id}/{project_id}/{filename}
-- so RLS can enforce isolation purely from the path, matching the
-- same rule used everywhere else: your org_id, and only your org_id.

create policy documents_bucket_select on storage.objects
  for select using (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = (
      select organization_id::text from profiles where id = auth.uid()
    )
  );

create policy documents_bucket_insert on storage.objects
  for insert with check (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = (
      select organization_id::text from profiles where id = auth.uid()
    )
  );

create policy documents_bucket_delete on storage.objects
  for delete using (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = (
      select organization_id::text from profiles where id = auth.uid()
    )
    and (
      (select role from profiles where id = auth.uid()) in ('admin', 'manager')
      or owner = auth.uid()
    )
  );
