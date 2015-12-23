module Directory_Service
  
  def openFile(directory_name, file_name)
    file = nil
    if File.directory?(directory_name)
      if File.exists?(file_name)
        return File.open(file_name)
      end
    end
    file
  end
  
  def closeFile(file)
    file.close
  end
  
  def writeFile(file)
  end
  
  def readFile(file)
    "hello"
  end
  
end
