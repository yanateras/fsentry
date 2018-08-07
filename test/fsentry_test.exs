defmodule FSentryTest do
  use ExUnit.Case

  def all_messages do
    receive do
      message ->
        [message | all_messages()]
    after
      0 -> []
    end
  end

  test "create/modify/delete events go through" do
    tmp_dir = System.tmp_dir!()
    {:ok, pid} = FSentry.start(tmp_dir)
    tmp_file = Path.join(tmp_dir, "fsentry")

    File.touch!(tmp_file)
    File.write!(tmp_file, "")
    File.rm!(tmp_file)

    assert [{_, "fsentry", :create},
	    {_, "fsentry", :modify},
	    {_, "fsentry", :delete}] = all_messages()

    FSentry.stop(pid)
  end
end
