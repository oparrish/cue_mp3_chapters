require 'rubycue'
require 'mp3info'
require 'optparse'

options = {}
 
opts = OptionParser.new do |opts| 
    opts.on("-c", "--cue PATH", "Path to chesheet file") do |cue_file|
      options[:cue] = cue_file
    end
    opts.on("-m", "--mp3 PATH", "Path to MP3 file") do |mp3_file|
      options[:mp3] = mp3_file
    end
end
 
opts.parse!

cuesheet = RubyCue::Cuesheet.new(File.read(options[:cue]))
cuesheet.parse!

Mp3Info.open(options[:mp3]) do |mp3|
  if (cuesheet.songs.size > 0) then
    chaps = []
    ctoc = "toc1\x00"
    ctoc << [3, cuesheet.songs.size].pack("CC")
    cuesheet.songs.each_with_index do |song, i|
      num = i+1
      title = "#{song[:performer]} - #{song[:title]}"
      description = ""
      link = ""
      
      ctoc << "ch#{num}\x00"
    
      chap = "ch#{num}\x00"
      chap << [song[:index].to_i, song[:incex] + song[:duration]].pack("NN");
      chap << "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
    
      title_tag = [title.encode("utf-16")].pack("a*");
      chap << "TIT2"
      chap << [title_tag.size+1].pack("N")
      chap << "\x00\x00\x01"
    	chap << title_tag
    
      if !description.nil? then
      	description_tag = [description.encode("utf-16")].pack("a*")
        chap << "TIT3"
        chap << [description_tag.size+1].pack("N")
        chap << "\x00\x00\x01"
        chap << description_tag
      end
      
      if !link.nil? then
        chap << "WXXX"
        chap << [link.length+2].pack("N")
        chap << "\x00\x00\x00#{link}\00"
      end
    
      chaps << chap
    end
    mp3.tag2.CTOC = ctoc
    mp3.tag2.CHAP = chaps
  end
end

