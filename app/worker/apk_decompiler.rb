require 'timeout'

class ApkDecompiler
  include Sidekiq::Worker
  sidekiq_options :queue => name.underscore, :retry => false

  def perform(apk_id)
    apk = Apk.find(apk_id)
    Source.purge_index!(apk)
    begin
      Timeout::timeout(1.minute) do
        Decompiler.decompile(apk.file, apk.source_dir)
      end
      Source.index_sources!(apk)
      apk.update_attributes(:decompiled => true)
    rescue Exception => e
      if e.message =~ /Crashed/
        # swallow
      elsif e.message =~ /dex2jar failed/
        # swallow
      else
        Source.purge_index!(apk)
        raise e
      end
    ensure
      FileUtils.rm_rf(apk.source_dir)
    end
  end
end
