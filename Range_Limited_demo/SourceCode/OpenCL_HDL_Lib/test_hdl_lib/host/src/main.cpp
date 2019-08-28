// Copyright (C) 2013-2018 Altera Corporation, San Jose, California, USA. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
// whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// 
// This agreement shall be governed in all respects by the laws of the State of California and
// by the laws of the United States of America.

///////////////////////////////////////////////////////////////////////////////////
// This host program executes a vector addition kernel to perform:
//  C = A + B
// where A, B and C are vectors with N elements.
//
// This host program supports partitioning the problem across multiple OpenCL
// devices if available. If there are M available devices, the problem is
// divided so that each device operates on N/M points. The host program
// assumes that all devices are of the same type (that is, the same binary can
// be used), but the code can be generalized to support different device types
// easily.
//
// Verification is performed against the same computation on the host CPU.
///////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "CL/opencl.h"
#include "AOCLUtils/aocl_utils.h"

using namespace aocl_utils;

// OpenCL runtime configuration
cl_platform_id platform = NULL;
unsigned num_devices = 1;
scoped_array<cl_device_id> device; // num_devices elements
cl_context context = NULL;
scoped_array<cl_command_queue> queue; // num_devices elements
cl_program program = NULL;
scoped_array<cl_kernel> kernel; // num_devices elements
#if USE_SVM_API == 0
scoped_array<cl_mem> input_ref_id_buf;
scoped_array<cl_mem> input_neighbor_id_buf; 
scoped_array<cl_mem> input_ref_x_buf; // num_devices elements
scoped_array<cl_mem> input_ref_y_buf; // num_devices elements
scoped_array<cl_mem> input_ref_z_buf; // num_devices elements
scoped_array<cl_mem> input_neighbor_x_buf; // num_devices elements
scoped_array<cl_mem> input_neighbor_y_buf; // num_devices elements
scoped_array<cl_mem> input_neighbor_z_buf; // num_devices elements
//scoped_array<cl_mem> output_buf; // num_devices elements
scoped_array<cl_mem> output_x_buf; // num_devices elements
scoped_array<cl_mem> output_y_buf; // num_devices elements
scoped_array<cl_mem> output_z_buf; // num_devices elements
#endif /* USE_SVM_API == 0 */

// Problem data.
unsigned N = 5; // problem size
#if USE_SVM_API == 0
scoped_array<scoped_aligned_ptr<int> > ref_id, neighbor_id; // num_devices elements
scoped_array<scoped_aligned_ptr<float> > ref_x, ref_y, ref_z, neighbor_x, neighbor_y, neighbor_z; // num_devices elements
//scoped_array<scoped_aligned_ptr<float> > Force_out; // num_devices elements
scoped_array<scoped_aligned_ptr<float> > Force_out_x; // num_devices elements
scoped_array<scoped_aligned_ptr<float> > Force_out_y; // num_devices elements
scoped_array<scoped_aligned_ptr<float> > Force_out_z; // num_devices elements
#else
scoped_array<scoped_SVM_aligned_ptr<int> > ref_id, neighbor_id; // num_devices elements
scoped_array<scoped_SVM_aligned_ptr<float> > ref_x, ref_y, ref_z, neighbor_x, neighbor_y, neighbor_z; // num_devices elements
//scoped_array<scoped_SVM_aligned_ptr<float> > Force_out; // num_devices elements
scoped_array<scoped_SVM_aligned_ptr<float> > Force_out_x; // num_devices elements
scoped_array<scoped_SVM_aligned_ptr<float> > Force_out_y; // num_devices elements
scoped_array<scoped_SVM_aligned_ptr<float> > Force_out_z; // num_devices elements

#endif /* USE_SVM_API == 0 */
scoped_array<scoped_array<float> > ref_output; // num_devices elements
scoped_array<unsigned> n_per_device; // num_devices elements

// Function prototypes
float rand_float();
bool init_opencl();
void init_problem();
void run();
void cleanup();

// Entry point.
int main(int argc, char **argv) {
  Options options(argc, argv);

  // Optional argument to specify the problem size.
  if(options.has("n")) {
    N = options.get<unsigned>("n");
  }

  // Initialize OpenCL.
  if(!init_opencl()) {
    return -1;
  }

  // Initialize the problem data.
  // Requires the number of devices to be known.
  printf("1, Problem initialization!\n");
  init_problem();

  // Run the kernel.
  printf("2, Run the kernel!\n");
  run();

  // Free the resources allocated
  printf("3, Cleanup the memory space!\n");
  cleanup();

  return 0;
}

/////// HELPER FUNCTIONS ///////

// Randomly generate a floating-point number between -10 and 10.
float rand_float() {
  return float(rand()) / float(RAND_MAX) * 20.0f - 10.0f;
}

// Initializes the OpenCL objects.
bool init_opencl() {
  cl_int status;

  printf("Initializing OpenCL\n");

  if(!setCwdToExeDir()) {
    return false;
  }

  // Get the OpenCL platform.
  platform = findPlatform("Intel(R) FPGA SDK for OpenCL(TM)");
  if(platform == NULL) {
    printf("ERROR: Unable to find Intel(R) FPGA OpenCL platform.\n");
    return false;
  }

  // Query the available OpenCL device.
  device.reset(getDevices(platform, CL_DEVICE_TYPE_ALL, &num_devices));
  printf("Platform: %s\n", getPlatformName(platform).c_str());
  printf("Using %d device(s)\n", num_devices);
  for(unsigned i = 0; i < num_devices; ++i) {
    printf("  %s\n", getDeviceName(device[i]).c_str());
  }

  // Create the context.
  context = clCreateContext(NULL, num_devices, device, &oclContextCallback, NULL, &status);
  checkError(status, "Failed to create context");

  // Create the program for all device. Use the first device as the
  // representative device (assuming all device are of the same type).
  std::string binary_file = getBoardBinaryFile("LJ", device[0]);
  printf("Using AOCX: %s\n", binary_file.c_str());
  program = createProgramFromBinary(context, binary_file.c_str(), device, num_devices);

  // Build the program that was just created.
  status = clBuildProgram(program, 0, NULL, "", NULL, NULL);
  checkError(status, "Failed to build program");

  // Create per-device objects.
  queue.reset(num_devices);
  kernel.reset(num_devices);
  n_per_device.reset(num_devices);
#if USE_SVM_API == 0
  input_ref_id_buf.reset(num_devices);
  input_neighbor_id_buf.reset(num_devices);
  input_ref_x_buf.reset(num_devices);
  input_ref_y_buf.reset(num_devices);
  input_ref_z_buf.reset(num_devices);
  input_neighbor_x_buf.reset(num_devices);
  input_neighbor_y_buf.reset(num_devices);
  input_neighbor_z_buf.reset(num_devices);
  //output_buf.reset(num_devices);
  output_x_buf.reset(num_devices);
  output_y_buf.reset(num_devices);
  output_z_buf.reset(num_devices);
#endif /* USE_SVM_API == 0 */

  for(unsigned i = 0; i < num_devices; ++i) {
    // Command queue.
    queue[i] = clCreateCommandQueue(context, device[i], CL_QUEUE_PROFILING_ENABLE, &status);
    checkError(status, "Failed to create command queue");

    // Kernel.
    const char *kernel_name = "LJ";
    kernel[i] = clCreateKernel(program, kernel_name, &status);
    checkError(status, "Failed to create kernel");

    // Determine the number of elements processed by this device.
    n_per_device[i] = N / num_devices; // number of elements handled by this device

    // Spread out the remainder of the elements over the first
    // N % num_devices.
    if(i < (N % num_devices)) {
      n_per_device[i]++;
    }

#if USE_SVM_API == 0
    // Input buffers.
	input_ref_id_buf[i] = clCreateBuffer(context, CL_MEM_READ_ONLY, 
        n_per_device[i] * sizeof(int), NULL, &status);
		
	input_neighbor_id_buf[i] = clCreateBuffer(context, CL_MEM_READ_ONLY, 
        n_per_device[i] * sizeof(int), NULL, &status);
	
    input_ref_x_buf[i] = clCreateBuffer(context, CL_MEM_READ_ONLY, 
        n_per_device[i] * sizeof(float), NULL, &status);
    checkError(status, "Failed to create buffer for input ref_x");

    input_ref_y_buf[i] = clCreateBuffer(context, CL_MEM_READ_ONLY, 
        n_per_device[i] * sizeof(float), NULL, &status);
    checkError(status, "Failed to create buffer for input ref_y");
	
	input_ref_z_buf[i] = clCreateBuffer(context, CL_MEM_READ_ONLY, 
        n_per_device[i] * sizeof(float), NULL, &status);
    checkError(status, "Failed to create buffer for input ref_z");
	
	input_neighbor_x_buf[i] = clCreateBuffer(context, CL_MEM_READ_ONLY, 
        n_per_device[i] * sizeof(float), NULL, &status);
    checkError(status, "Failed to create buffer for input neighbor_x");
	
	input_neighbor_y_buf[i] = clCreateBuffer(context, CL_MEM_READ_ONLY, 
        n_per_device[i] * sizeof(float), NULL, &status);
    checkError(status, "Failed to create buffer for input neighbor_y");
	
	input_neighbor_z_buf[i] = clCreateBuffer(context, CL_MEM_READ_ONLY, 
        n_per_device[i] * sizeof(float), NULL, &status);
    checkError(status, "Failed to create buffer for input neighbor_z");

    // Output buffer.
    //output_buf[i] = clCreateBuffer(context, CL_MEM_WRITE_ONLY, 
    //    n_per_device[i] * sizeof(float), NULL, &status);
    //checkError(status, "Failed to create buffer for output");
	output_x_buf[i] = clCreateBuffer(context, CL_MEM_WRITE_ONLY, 
        n_per_device[i] * sizeof(float), NULL, &status);
    checkError(status, "Failed to create buffer for output");
	output_y_buf[i] = clCreateBuffer(context, CL_MEM_WRITE_ONLY, 
        n_per_device[i] * sizeof(float), NULL, &status);
    checkError(status, "Failed to create buffer for output");
	output_z_buf[i] = clCreateBuffer(context, CL_MEM_WRITE_ONLY, 
        n_per_device[i] * sizeof(float), NULL, &status);
    checkError(status, "Failed to create buffer for output");
#else
    cl_device_svm_capabilities caps = 0;

    status = clGetDeviceInfo(
      device[i],
      CL_DEVICE_SVM_CAPABILITIES,
      sizeof(cl_device_svm_capabilities),
      &caps,
      0
    );
    checkError(status, "Failed to get device info");

    if (!(caps & CL_DEVICE_SVM_COARSE_GRAIN_BUFFER)) {
      printf("The host was compiled with USE_SVM_API, however the device currently being targeted does not support SVM.\n");
      // Free the resources allocated
      cleanup();
      return false;
    }
#endif /* USE_SVM_API == 0 */
  }

  return true;
}

// Initialize the data for the problem. Requires num_devices to be known.
void init_problem() {
  if(num_devices == 0) {
    checkError(-1, "No devices");
  }

  ref_id.reset(num_devices);
  neighbor_id.reset(num_devices);
  ref_x.reset(num_devices);
  ref_y.reset(num_devices);
  ref_z.reset(num_devices);
  neighbor_x.reset(num_devices);
  neighbor_y.reset(num_devices);
  neighbor_z.reset(num_devices);
  //Force_out.reset(num_devices);
  Force_out_x.reset(num_devices);
  Force_out_y.reset(num_devices);
  Force_out_z.reset(num_devices);
  ref_output.reset(num_devices);

  // Generate input vectors A and B and the reference output consisting
  // of a total of N elements.
  // We create separate arrays for each device so that each device has an
  // aligned buffer.
  for(unsigned i = 0; i < num_devices; ++i) {
#if USE_SVM_API == 0
	ref_id[i].reset(n_per_device[i]);
	neighbor_id[i].reset(n_per_device[i]);
    ref_x[i].reset(n_per_device[i]);
    ref_y[i].reset(n_per_device[i]);
	ref_z[i].reset(n_per_device[i]);
	neighbor_x[i].reset(n_per_device[i]);
	neighbor_y[i].reset(n_per_device[i]);
	neighbor_z[i].reset(n_per_device[i]);
    //Force_out[i].reset(n_per_device[i]);
	Force_out_x[i].reset(n_per_device[i]);
	Force_out_y[i].reset(n_per_device[i]);
	Force_out_z[i].reset(n_per_device[i]);
    ref_output[i].reset(n_per_device[i]);

    for(unsigned j = 0; j < n_per_device[i]; ++j) {
	  ref_id[i][j] = j;
	  neighbor_id[i][j] = j;
      ref_x[i][j] = 14.410;
	  ref_y[i][j] = 12.083;
	  ref_z[i][j] = 14.591;
      neighbor_x[i][j] = 15.099;
      neighbor_y[i][j] = 12.267;
      neighbor_z[i][j] = 25.249;
      ref_output[i][j] = ref_x[i][j] + neighbor_x[i][j];
    }
#else
	ref_id[i].reset(context, n_per_device[i]);
	neighbor_id[i].reset(context, n_per_device[i]);
    ref_x[i].reset(context, n_per_device[i]);
	ref_y[i].reset(context, n_per_device[i]);
	ref_z[i].reset(context, n_per_device[i]);
    neighbor_x[i].reset(context, n_per_device[i]);
	neighbor_y[i].reset(context, n_per_device[i]);
	neighbor_z[i].reset(context, n_per_device[i]);
    //Force_out[i].reset(context, n_per_device[i]);
	Force_out_x[i].reset(context, n_per_device[i]);
	Force_out_y[i].reset(context, n_per_device[i]);
	Force_out_z[i].reset(context, n_per_device[i]);
    ref_output[i].reset(n_per_device[i]);

    cl_int status;

    status = clEnqueueSVMMap(queue[i], CL_TRUE, CL_MAP_WRITE,
        (void *)ref_id[i], n_per_device[i] * sizeof(int), 0, NULL, NULL);
    checkError(status, "Failed to map input: ref id");
	status = clEnqueueSVMMap(queue[i], CL_TRUE, CL_MAP_WRITE,
        (void *)neighbor_id[i], n_per_device[i] * sizeof(int), 0, NULL, NULL);
    checkError(status, "Failed to map input: neighbor id");
    status = clEnqueueSVMMap(queue[i], CL_TRUE, CL_MAP_WRITE,
        (void *)ref_x[i], n_per_device[i] * sizeof(float), 0, NULL, NULL);
    checkError(status, "Failed to map input: ref_x");
	status = clEnqueueSVMMap(queue[i], CL_TRUE, CL_MAP_WRITE,
        (void *)ref_y[i], n_per_device[i] * sizeof(float), 0, NULL, NULL);
    checkError(status, "Failed to map input: ref_y");
	status = clEnqueueSVMMap(queue[i], CL_TRUE, CL_MAP_WRITE,
        (void *)ref_z[i], n_per_device[i] * sizeof(float), 0, NULL, NULL);
    checkError(status, "Failed to map input: ref_z");
	status = clEnqueueSVMMap(queue[i], CL_TRUE, CL_MAP_WRITE,
        (void *)neighbor_x[i], n_per_device[i] * sizeof(float), 0, NULL, NULL);
    checkError(status, "Failed to map input: neighbor_x");
	status = clEnqueueSVMMap(queue[i], CL_TRUE, CL_MAP_WRITE,
        (void *)neighbor_y[i], n_per_device[i] * sizeof(float), 0, NULL, NULL);
    checkError(status, "Failed to map input: neighbor_y");
	status = clEnqueueSVMMap(queue[i], CL_TRUE, CL_MAP_WRITE,
        (void *)neighbor_z[i], n_per_device[i] * sizeof(float), 0, NULL, NULL);
    checkError(status, "Failed to map input: neighbor_z");

    for(unsigned j = 0; j < n_per_device[i]; ++j) {
	  ref_id[i][j] = j;
	  neighbor_id[i][j] = j;
      ref_x[i][j] = 14.410;
	  ref_y[i][j] = 12.083;
	  ref_z[i][j] = 14.591;
      neighbor_x[i][j] = 15.099;
      neighbor_y[i][j] = 12.267;
      neighbor_z[i][j] = 25.249;
      ref_output[i][j] = input_a[i][j] + input_b[i][j];
    }

	status = clEnqueueSVMUnmap(queue[i], (void *)ref_id[i], 0, NULL, NULL);
    checkError(status, "Failed to unmap input ref_id");
	status = clEnqueueSVMUnmap(queue[i], (void *)neighbor_id[i], 0, NULL, NULL);
    checkError(status, "Failed to unmap input neighbor_id");
    status = clEnqueueSVMUnmap(queue[i], (void *)ref_x[i], 0, NULL, NULL);
    checkError(status, "Failed to unmap input ref_x");
	status = clEnqueueSVMUnmap(queue[i], (void *)ref_y[i], 0, NULL, NULL);
    checkError(status, "Failed to unmap input ref_y");
	status = clEnqueueSVMUnmap(queue[i], (void *)ref_z[i], 0, NULL, NULL);
    checkError(status, "Failed to unmap input ref_z");
    status = clEnqueueSVMUnmap(queue[i], (void *)neighbor_x[i], 0, NULL, NULL);
    checkError(status, "Failed to unmap input neighbor_x");
	status = clEnqueueSVMUnmap(queue[i], (void *)neighbor_y[i], 0, NULL, NULL);
    checkError(status, "Failed to unmap input neighbor_y")
	status = clEnqueueSVMUnmap(queue[i], (void *)neighbor_z[i], 0, NULL, NULL);
    checkError(status, "Failed to unmap input neighbor_z");
#endif /* USE_SVM_API == 0 */
  }
}

void run() {
  cl_int status;

  const double start_time = getCurrentTimestamp();

  // Launch the problem for each device.
  scoped_array<cl_event> kernel_event(num_devices);
  scoped_array<cl_event> finish_event1(num_devices);
  scoped_array<cl_event> finish_event2(num_devices);
  scoped_array<cl_event> finish_event3(num_devices);

  for(unsigned i = 0; i < num_devices; ++i) {

#if USE_SVM_API == 0
    // Transfer inputs to each device. Each of the host buffers supplied to
    // clEnqueueWriteBuffer here is already aligned to ensure that DMA is used
    // for the host-to-device transfer.
    cl_event write_event[8];
	status = clEnqueueWriteBuffer(queue[i], input_ref_id_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(int), ref_id[i], 0, NULL, &write_event[0]);
    checkError(status, "Failed to transfer input ref_id");
	
	status = clEnqueueWriteBuffer(queue[i], input_neighbor_id_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(float), neighbor_id[i], 0, NULL, &write_event[1]);
    checkError(status, "Failed to transfer input neighbor_id");
	
    status = clEnqueueWriteBuffer(queue[i], input_ref_x_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(float), ref_x[i], 0, NULL, &write_event[2]);
    checkError(status, "Failed to transfer input ref_x");
	
	status = clEnqueueWriteBuffer(queue[i], input_ref_y_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(float), ref_y[i], 0, NULL, &write_event[3]);
    checkError(status, "Failed to transfer input ref_y");
	
	status = clEnqueueWriteBuffer(queue[i], input_ref_z_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(float), ref_z[i], 0, NULL, &write_event[4]);
    checkError(status, "Failed to transfer input ref_z");

    status = clEnqueueWriteBuffer(queue[i], input_neighbor_x_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(float), neighbor_x[i], 0, NULL, &write_event[5]);
    checkError(status, "Failed to transfer input neighbor_x");
	
	status = clEnqueueWriteBuffer(queue[i], input_neighbor_y_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(float), neighbor_y[i], 0, NULL, &write_event[6]);
    checkError(status, "Failed to transfer input neighbor_y");
	
	status = clEnqueueWriteBuffer(queue[i], input_neighbor_z_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(float), neighbor_z[i], 0, NULL, &write_event[7]);
    checkError(status, "Failed to transfer input neighbor_z");
#endif /* USE_SVM_API == 0 */

    // Set kernel arguments.
    unsigned argi = 0;

#if USE_SVM_API == 0
	status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &input_ref_id_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &input_neighbor_id_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
    
	status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &input_ref_x_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &input_ref_y_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &input_ref_z_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);

    status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &input_neighbor_x_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &input_neighbor_y_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &input_neighbor_z_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);

    //status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &output_buf[i]);
    //checkError(status, "Failed to set argument %d", argi - 1);
	status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &output_x_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &output_y_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &output_z_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
#else
    status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)input_ref_id_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);

    status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)input_neighbor_id_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)input_ref_x_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)input_ref_y_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)input_ref_z_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)input_neighbor_x_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)input_neighbor_y_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)input_neighbor_z_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);

    status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)output_x_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)output_y_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
	
	status = clSetKernelArgSVMPointer(kernel[i], argi++, (void*)output_z_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);
#endif /* USE_SVM_API == 0 */

    // Enqueue kernel.
    // Use a global work size corresponding to the number of elements to add
    // for this device.
    //
    // We don't specify a local work size and let the runtime choose
    // (it'll choose to use one work-group with the same size as the global
    // work-size).
    //
    // Events are used to ensure that the kernel is not launched until
    // the writes to the input buffers have completed.
    const size_t global_work_size = n_per_device[i];
    printf("Launching for device %d (%zd elements)\n", i, global_work_size);

	printf("************** Kernel enqueued!\n");
	
#if USE_SVM_API == 0
    status = clEnqueueNDRangeKernel(queue[i], kernel[i], 1, NULL,
        &global_work_size, NULL, 8, write_event, &kernel_event[i]);
#else
    status = clEnqueueNDRangeKernel(queue[i], kernel[i], 1, NULL,
        &global_work_size, NULL, 0, NULL, &kernel_event[i]);
#endif /* USE_SVM_API == 0 */
    checkError(status, "Failed to launch kernel");

	printf("************* Kernel enqueue finished!\n");
	
#if USE_SVM_API == 0
    // Read the result. This the final operation.
    //status = clEnqueueReadBuffer(queue[i], output_buf[i], CL_FALSE,
    //    0, n_per_device[i] * sizeof(float), Force_out, 1, &kernel_event[i], &finish_event[i]);
	status = clEnqueueReadBuffer(queue[i], output_x_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(float), Force_out_x[i], 1, &kernel_event[i], &finish_event1[i]);
	status = clEnqueueReadBuffer(queue[i], output_y_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(float), Force_out_y[i], 1, &kernel_event[i], &finish_event2[i]);
	status = clEnqueueReadBuffer(queue[i], output_z_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(float), Force_out_z[i], 1, &kernel_event[i], &finish_event3[i]);

	printf("!!!!!!!!!! Output buffer read finished!\n");
		
    // Release local events.
    clReleaseEvent(write_event[0]);
	printf("~~~~ Release write event 0!\n");
    clReleaseEvent(write_event[1]);
	printf("~~~~ Release write event 1!\n");
	clReleaseEvent(write_event[2]);
	printf("~~~~ Release write event 2!\n");
	clReleaseEvent(write_event[3]);
	printf("~~~~ Release write event 3!\n");
	clReleaseEvent(write_event[4]);
	printf("~~~~ Release write event 4!\n");
	clReleaseEvent(write_event[5]);
	printf("~~~~ Release write event 5!\n");
	clReleaseEvent(write_event[6]);
	printf("~~~~ Release write event 6!\n");
	clReleaseEvent(write_event[7]);
	printf("~~~~ Release write event 7!\n");
#else
    status = clEnqueueSVMMap(queue[i], CL_TRUE, CL_MAP_READ,
        (void *)output[i], n_per_device[i] * sizeof(float), 0, NULL, NULL);
    checkError(status, "Failed to map output");
	clFinish(queue[i]);
#endif /* USE_SVM_API == 0 */
  }

  // Wait for all devices to finish.
  clWaitForEvents(num_devices, finish_event1);
  printf("**** Read Event 1 finish!\n");
  clWaitForEvents(num_devices, finish_event2);
  printf("**** Read Event 2 finish!\n");
  clWaitForEvents(num_devices, finish_event3);
  printf("**** Read Event 3 finish!\n");
  
  const double end_time = getCurrentTimestamp();

  // Wall-clock time taken.
  printf("\nTime: %0.3f ms\n", (end_time - start_time) * 1e3);

  // Get kernel times using the OpenCL event profiling API.
  for(unsigned i = 0; i < num_devices; ++i) {
    cl_ulong time_ns = getStartEndTime(kernel_event[i]);
    printf("Kernel time (device %d): %0.3f ms\n", i, double(time_ns) * 1e-6);
  }

  // Release all events.
  for(unsigned i = 0; i < num_devices; ++i) {
    clReleaseEvent(kernel_event[i]);
    clReleaseEvent(finish_event1[i]);
	clReleaseEvent(finish_event2[i]);
	clReleaseEvent(finish_event3[i]);
  }

/*   // Verify results.
  bool pass = true;
  for(unsigned i = 0; i < num_devices && pass; ++i) {
    for(unsigned j = 0; j < n_per_device[i] && pass; ++j) {
      if(fabsf(output[i][j] - ref_output[i][j]) > 1.0e-5f) {
        printf("Failed verification @ device %d, index %d\nOutput: %f\nReference: %f\n",
            i, j, output[i][j], ref_output[i][j]);
        pass = false;
      }
    }
  } */

#if USE_SVM_API == 1
  for (unsigned i = 0; i < num_devices; ++i) {
    status = clEnqueueSVMUnmap(queue[i], (void *)output[i], 0, NULL, NULL);
    checkError(status, "Failed to unmap output");
  }
#endif /* USE_SVM_API == 1 */
  //printf("\nVerification: %s\n", pass ? "PASS" : "FAIL");
  
  // Printf out results
  printf("@@ Evaluation results report:\n");
  for(unsigned i = 0; i < n_per_device[0]; i++){
	  printf("Results[%d], %e, %e, %e\n", i, Force_out_x[0][i], Force_out_y[0][i], Force_out_z[0][i]);
  }
  printf("@@ Results report done!\n");
}

// Free the resources allocated during initialization
void cleanup() {
  for(unsigned i = 0; i < num_devices; ++i) {
    if(kernel && kernel[i]) {
      clReleaseKernel(kernel[i]);
    }
    if(queue && queue[i]) {
      clReleaseCommandQueue(queue[i]);
    }
#if USE_SVM_API == 0
	if(input_ref_id_buf && input_ref_id_buf[i]) {
      clReleaseMemObject(input_ref_id_buf[i]);
    }
	if(input_neighbor_id_buf && input_neighbor_id_buf[i]) {
      clReleaseMemObject(input_neighbor_id_buf[i]);
    }
    if(input_ref_x_buf && input_ref_x_buf[i]) {
      clReleaseMemObject(input_ref_x_buf[i]);
    }
	if(input_ref_y_buf && input_ref_y_buf[i]) {
      clReleaseMemObject(input_ref_y_buf[i]);
    }
	if(input_ref_z_buf && input_ref_z_buf[i]) {
      clReleaseMemObject(input_ref_z_buf[i]);
    }
    if(input_neighbor_x_buf && input_neighbor_x_buf[i]) {
      clReleaseMemObject(input_neighbor_x_buf[i]);
    }
	if(input_neighbor_y_buf && input_neighbor_y_buf[i]) {
      clReleaseMemObject(input_neighbor_y_buf[i]);
    }
	if(input_neighbor_z_buf && input_neighbor_z_buf[i]) {
      clReleaseMemObject(input_neighbor_z_buf[i]);
    }
    //if(output_buf && output_buf[i]) {
    //  clReleaseMemObject(output_buf[i]);
    //}
	if(output_x_buf && output_x_buf[i]) {
      clReleaseMemObject(output_x_buf[i]);
    }
	if(output_y_buf && output_y_buf[i]) {
      clReleaseMemObject(output_y_buf[i]);
    }
	if(output_z_buf && output_z_buf[i]) {
      clReleaseMemObject(output_z_buf[i]);
    }
	
#else
    if(input_ref_id_buf[i].get())
      input_ref_id_buf[i].reset();
    if(input_neighbor_id_buf[i].get())
      input_neighbor_id_buf[i].reset();
    if(input_ref_x_buf[i].get())
      input_ref_x_buf[i].reset();
    if(input_ref_y_buf[i].get())
      input_ref_y_buf[i].reset();
    if(input_ref_z_buf[i].get())
      input_ref_z_buf[i].reset();
    if(input_neighbor_x_buf[i].get())
      input_neighbor_x_buf[i].reset();
    if(input_neighbor_y_buf[i].get())
      input_neighbor_y_buf[i].reset();
    if(input_neighbor_z_buf[i].get())
      input_neighbor_z_buf[i].reset();
    if(output_x_buf[i].get())
      output_x_buf[i].reset();
    if(output_y_buf[i].get())
      output_y_buf[i].reset();
    if(output_z_buf[i].get())
      output_z_buf[i].reset();
#endif /* USE_SVM_API == 0 */
  }

  if(program) {
    clReleaseProgram(program);
  }
  if(context) {
    clReleaseContext(context);
  }
}

