//build@ gcc -fno-for-scope -DINTEL -O2 -o ttc2ttf ttc2ttf.c

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <ctype.h>
#include <sys/stat.h>

#ifdef INTEL
  #define swaps(x)        ((((x)&0xFF)<<8) + (((x)>>8)&0xFF))
  #define swapl(x)        ((((x)&0xFF)<<24)       \
                         +(((x)>>24)&0xFF)       \
                         +(((x)&0x0000FF00)<<8)  \
                         +(((x)&0x00FF0000)>>8)  )
#endif


unsigned long CalcTableChecksum(unsigned long* table, unsigned long length);

main(int argc, char* argv[])
{
	if (argc != 2) {
		printf("Usage: ttc2ttf filename\n");
		exit(2);
	}

	char*		filename = argv[1];
	FILE*		in_file = fopen(filename, "rb");
	long i;
	if (in_file == NULL) {
		printf("\"%s\" not found\n", filename);
		exit(2);
	}
	struct	stat	info;
	fstat(fileno(in_file), &info);
	char*			buffer = (char*) malloc(info.st_size);
	fread(buffer, sizeof(char), info.st_size, in_file);
	fclose(in_file);
	
	if (strlen(filename) > 4) {
		char	tmp[5];
		strcpy(tmp, &filename[strlen(filename) - 4]);
		for (i = 0; i < 4; i++)
			tmp[i] = toupper(tmp[i]);
		if (strcmp(tmp, ".TTC") == 0)
			filename[strlen(filename) - 4] = 0;
	}
#ifdef INTEL
	if (swapl(*(long*) buffer) != 'ttcf')
#else
	if (*(long*) buffer != 'ttcf')
#endif
	{
		char	out_filename[256];
		sprintf(out_filename, "%s.ttf", filename);
		FILE*	out_file = fopen(out_filename, "wb");
		fwrite(buffer, sizeof(char), info.st_size, out_file);
		fclose(out_file);
	}
	else
	{
#ifdef INTEL
	   unsigned long   ttf_count = swapl(*(unsigned long*) &buffer[0x08]);
# else
		unsigned long	ttf_count = *(unsigned long*) &buffer[0x08];
#endif

		unsigned long*	ttf_offset_array = (unsigned long*) &buffer[0x0C];
		
		unsigned long i;

		for (i = 0; i < ttf_count; i++) {

#ifdef INTEL 
           unsigned long       table_header_offset = swapl(ttf_offset_array[i]);
           unsigned short      table_count = swaps(*(unsigned short*) &buffer[table_header_offset + 0x04]);


# else
			unsigned long		table_header_offset = ttf_offset_array[i];
			unsigned short		table_count = *(unsigned short*) &buffer[table_header_offset + 0x04];
#endif
			unsigned long		header_length = 0x0C + table_count * 0x10;
			unsigned long		table_length = 0;
			unsigned short j;

			for (j = 0; j < table_count; j++) {
#ifdef INTEL
			unsigned long   length = swapl(*(unsigned long*) &buffer[table_header_offset + 0x0C + 0x0C + j * 0x10]);

# else
				unsigned long	length = *(unsigned long*) &buffer[table_header_offset + 0x0C + 0x0C + j * 0x10];
#endif

				table_length += (length + 3) & ~3;
			}
			unsigned long	total_length = header_length + table_length;
			char*			new_buffer = (char*) malloc(total_length);
			unsigned long	pad = 0;
			memcpy(new_buffer, &buffer[table_header_offset], header_length);
			unsigned long	current_offset = header_length;

			for (j = 0; j < table_count; j++) {
#ifdef INTEL
               unsigned long   offset = swapl(*(unsigned long*) &buffer[table_header_offset + 0x0C + 0x08 + j * 0x10]);
               unsigned long   length = swapl(*(unsigned long*) &buffer[table_header_offset + 0x0C + 0x0C + j * 0x10]);
               *(unsigned long*) &new_buffer[0x0C + 0x08 + j * 0x10] = swapl(current_offset);
# else
				unsigned long	offset = *(unsigned long*) &buffer[table_header_offset + 0x0C + 0x08 + j * 0x10];
				unsigned long	length = *(unsigned long*) &buffer[table_header_offset + 0x0C + 0x0C + j * 0x10];
				*(unsigned long*) &new_buffer[0x0C + 0x08 + j * 0x10] = current_offset;
#endif
				memcpy(&new_buffer[current_offset], &buffer[offset], length);
				memcpy(&new_buffer[current_offset + length], &pad, ((length + 3) & ~3) - length);

#ifdef INTEL

               *(unsigned long*) &new_buffer[0x0C + 0x04 + j * 0x10] = swapl(CalcTableChecksum((unsigned long*) &new_buffer[current_offset], length));
# else
				*(unsigned long*) &new_buffer[0x0C + 0x04 + j * 0x10] = CalcTableChecksum((unsigned long*) &new_buffer[current_offset], length);
#endif

				current_offset += (length + 3) & ~3;
			}

			char	out_filename[256];
			sprintf(out_filename, "%s%d.ttf", filename, i);
			FILE*	out_file = fopen(out_filename, "wb");
			fwrite(new_buffer, sizeof(char), total_length, out_file);
			fclose(out_file);
			free(new_buffer);
		}
	}
	free(buffer);
}
unsigned long
CalcTableChecksum(unsigned long* table, unsigned long length)
{
	unsigned long	sum = 0L;
	unsigned long*	end_ptr = table + ((length + 3) & ~3) / sizeof(unsigned long);
	while (table < end_ptr)
#ifdef INTEL
		sum += swapl(*table++);
# else
		sum += *table++;
# endif
	return sum;
}
