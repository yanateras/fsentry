defmodule FSentryTest do
  use ExUnit.Case

  def all_messages do
    receive do
      message -> [message | all_messages()]
    after
      0 -> []
    end
  end

  test "create/modify/delete events go through" do
    tmp = System.tmp_dir!()
    pid = FSentry.start!(tmp)
    tmp = Path.join(tmp, "fsentry")

    File.touch!(tmp)
    File.write!(tmp, "")
    File.rm!(tmp)

    assert [
             {_, "fsentry", :create},
             {_, "fsentry", :modify},
             {_, "fsentry", :delete}
           ] = all_messages()

    FSentry.stop(pid)
  end
end
