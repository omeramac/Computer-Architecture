#include <stdio.h>
#include <stdlib.h>
#include <string.h>	
extern "C" int func(char *source_bitmap, int scan_line_no, char*text);

int main(int argc, char *argv[])
{
//check the number of inputs, only program name and file name should be there
	if(argc != 2)
	{
		printf("Pass only the name of bmp file and scanned line!\n");
		return 0;
	}
	//output empty char string
	char text[50]={' '};
	//getting the file name
	char *name = argv[1];
    	FILE *file;
	char *source_bitmap;
  	//setting number for shifting pointer to middle of the image
  	int scan_line = 25;;
	unsigned long fileLenght;
	
	//open the file
	file = fopen(name, "rb");
	//file will return file pointer, otherwise NULL
	if (!file)
	{
		fprintf(stderr, "File: %s can not be opened.\n", name);
		return 1;
	}
	//placing the pointer to end of file
	fseek(file, 0, SEEK_END);
	//getting length of the file
	fileLenght=ftell(file);
	fseek(file, 0, SEEK_SET);
	//allocate memory for the process
	source_bitmap=(char *)malloc(fileLenght+1);
	//check if memory allocated correctly
	if (!source_bitmap)
	{
		printf("Memory allocation is not successful!\n");
        fclose(file);
		return 2;
	}

	//read the file in allocated memory
	fread(source_bitmap, fileLenght, 1, file);
	fclose(file);

	 char* bmp = source_bitmap; 
		//call the assembly code here
		int l = func(bmp, scan_line, text);
		//check the outputs of the assembly
		if(l == 1){	
			//1 is for bmp marker error
			printf("bmp marker error occured!!\n");
		}else if(l == 2){
			//2 is for size error
			printf("Size error occured!!!\n");
		}else{
			//0 is for successful run
			printf("Decoded text: %s \n ", text);
		}
	//clean the allocated memory
        free(source_bitmap);

	return 0;
}