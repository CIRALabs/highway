revision_file=Rails.root.join("REVISION")
if File.exist?(revision_file)
  $REVISION = IO::read(revision_file).chomp
end

