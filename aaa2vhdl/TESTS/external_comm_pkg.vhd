package external_comm_pkg is
  function get_addr(x : INTEGER) return INTEGER;
  attribute foreign of get_addr : function is "VHPIDIRECT get_addr";
  function send_result( res : INTEGER) return INTEGER;
  attribute foreign of send_result : function is "VHPIDIRECT send_result";
end external_comm_pkg;

package body external_comm_pkg is
  function get_addr(x : INTEGER) return INTEGER is
  begin
    assert false severity failure;
  end get_addr;
  function send_result(res : INTEGER) return INTEGER is
  begin
    assert false severity failure;
  end send_result;
end external_comm_pkg;
