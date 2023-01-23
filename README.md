# Bluespec Practice for ARDA Group

- This project requires [bluespecpcie](https://github.com/sangwoojun/bluespecpcie).
- Each example does the same job (mattress addition) in different ways (Except HelloWorld)
- Please place this directory under [/bluespecpcie/](https://github.com/sangwoojun/bluespecpcie) for compilation
-----------------------------------------  
## Compile and Run    
````sh    
$ make   
$ ./run.sh    

````

## 01-HelloWorld  
-----------------------------------------  
- Prints HelloWorld 10 times and Terminated using Bluesim.
-----------------------------------------  

## 02-BDPI  
-----------------------------------------   
- Matrix Addition using BDPI.
- BDPI connects .bsv code with C or Cpp files for simulation
-----------------------------------------  

## 03-PCIe  
-----------------------------------------   
- Matrix Addition using PCIe.
- This method uses Memory-Mapped I/O, the speed is around 30MB/sec
- Before using PCIe, please generate PCIe core referencing [bluespecpcie](https://github.com/sangwoojun/bluespecpcie)
-----------------------------------------  

## 04-DMA  
-----------------------------------------   
- Matrix Addition using DMA.
- This method uses Direct Memory Access, the ideal speed is almost 4GB/sec. 
-----------------------------------------  

## 05-BRAM  
-----------------------------------------   
- Matrix Addition using DMA and BRAM.
- Please reference the 'BramCtl.bsv' in the example and understand how to use BRAM in Bluespec. 
-----------------------------------------  

## 06-DRAM  
-----------------------------------------   
- Matrix Addition using DMA and DRAM.
- Before using DRAM, please generate DRAM core referencing [bluespecpcie](https://github.com/sangwoojun/bluespecpcie)
-----------------------------------------  
