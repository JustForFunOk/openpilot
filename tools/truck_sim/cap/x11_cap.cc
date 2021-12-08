
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <dlfcn.h>
#include <string.h>
#include <getopt.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundefined-inline"
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/opencv.hpp>
#include <opencv2/videoio.hpp>
#pragma clang diagnostic pop

#include "cereal/messaging/messaging.h"

#define N_FRAMES 100

#include <X11/Xlib.h>
#include <X11/Xutil.h>

// Bytes per pixel
static int Bpp = sizeof(uint8_t) * 3;
#define BITMAP_ROW_SIZE(width) (((width * Bpp) + 3) & ~3)
static PubSocket *pubSocket;
static Display* display = nullptr;
static Window root = 0;
static bool running = true;

// static int fid = 0;
inline void send_frame(const unsigned char *frame, const uint32_t frameId, const int width, const int height){
    int size = BITMAP_ROW_SIZE(width) * height;
    // FILE * fd = fopen("myfile.bin", "wb");
    // fwrite(frame, size, 1, fd);
    MessageBuilder msg;
    auto framed = msg.initEvent().initRoadCameraState();
    framed.setFrameId(frameId);
    framed.setImage(kj::arrayPtr((const uint8_t *)frame, size));
    framed.setTransform({
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0
    });
    auto bytes = msg.toBytes();
    
    pubSocket->send((char *)bytes.begin(), bytes.size());
}

uint64_t NvFBCUtilsGetTimeInMillis()
{
    struct timeval tv;

    gettimeofday(&tv, NULL);

    return ((uint64_t)tv.tv_sec * 1000000ULL + (uint64_t)tv.tv_usec) / 1000;
}

void ImageFromDisplay(std::vector<uint8_t>& Pixels, int& Width, int& Height, int& BitsPerPixel)
{
    XWindowAttributes attributes = {0};
    XGetWindowAttributes(display, root, &attributes);

    Width = attributes.width;
    Height = attributes.height;

    XImage* img = XGetImage(display, root, 0, 0 , Width, Height, AllPlanes, ZPixmap);
    BitsPerPixel = img->bits_per_pixel;
    Pixels.resize(Width * Height * 4);

    memcpy(&Pixels[0], img->data, Pixels.size());

    XDestroyImage(img);
}

/**
 * Initializes the NvFBC and CUDA libraries and creates an NvFBC instance.
 *
 * Creates and sets up a capture session to video memory using the CUDA interop.
 *
 * Captures a bunch of frames every second, converts them to BMP and saves them
 * to the disk.
 */
int main(int argc, char *argv[])
{
    display = XOpenDisplay(nullptr);
    root = DefaultRootWindow(display);


    pubSocket = PubSocket::create();
    pubSocket->connect(Context::create(), "roadCameraState");

    // struct timespec delay = {0, 50*1000000};
    /*
     * We are now ready to start grabbing frames.
     */
    // static unsigned char *frame = NULL;
    while (running) {

        uint64_t t1, t2, t1_total, t2_total, t_delta, wait_time_ms;

        t1 = NvFBCUtilsGetTimeInMillis();
        t1_total = t1;


        t2 = NvFBCUtilsGetTimeInMillis();

        // printf(", downloaded in %llu ms", (unsigned long long) (t2 - t1));

        // send_frame(frame, frameInfo.dwCurrentFrame, frameInfo.dwWidth, frameInfo.dwHeight);

        cv::Mat image, sendImg, outputImg;
        int Width = 1024;
        int Height = 768;
        std::vector<std::uint8_t> Pixels;
        ImageFromDisplay(Pixels, Width, Height, Bpp);
        cv::Mat img = cv::Mat(Height, Width, Bpp > 24 ? CV_8UC4 : CV_8UC3, &Pixels[0]);

        cv::imshow("test", img);
        cv::waitKey(1);

        t2_total = t2;


        printf ("image from display \n");

        /*
         * Compute how much time to sleep before capturing the next frame.
         */
        t_delta = t2_total - t1_total;
        wait_time_ms = t_delta < 50 ? 50 - t_delta : 0;
        // printf(", now sleeping for %llu ms\n",
        //        (unsigned long long) wait_time_ms);
        if(wait_time_ms > 0){
            usleep(wait_time_ms * 1000);
        }
    }

    XCloseDisplay(display);

    return EXIT_SUCCESS;
}
