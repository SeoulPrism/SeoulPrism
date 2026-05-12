-- admin_* RPC 함수들이 SECURITY DEFINER + 내부 _is_admin() 검사를 갖고 있지만,
-- 함수 자체에 authenticated 역할의 EXECUTE 권한이 없으면 PostgREST 가 SQL 레벨
-- permission denied (42501) 로 막아 내부 admin 검사에 도달하지 못한다.
-- _is_admin() 은 이미 authenticated 에게 EXECUTE 허용되어 있고, 각 admin_*
-- 함수 첫 줄이 _is_admin() 검사라 비-admin 호출은 거기서 차단된다 → 안전.
GRANT EXECUTE ON FUNCTION public.admin_get_metrics() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_abuse_signals() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_reports(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_report_status(uuid, text) TO authenticated;
