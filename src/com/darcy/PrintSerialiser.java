package com.darcy;

import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.geom.AffineTransform;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.Scanner;

import javax.imageio.ImageIO;

public class PrintSerialiser {
    public static final int RESOLUTION_LIMIT = 16;
    public static BufferedImage resize(BufferedImage img, int newW, int newH) {
        Image tmp = img.getScaledInstance(newW, newH, Image.SCALE_SMOOTH);
        BufferedImage dimg = new BufferedImage(newW, newH, BufferedImage.TYPE_INT_ARGB);

        Graphics2D g2d = dimg.createGraphics();
        g2d.drawImage(tmp, 0, 0, null);
        g2d.dispose();

        return dimg;
    }

    // simple function to get digits written to a file - to help file input on the lua side.
    public static int getDigits(int number){
        int output = 0;
        while(number > 0){
            number /= 10;
            output += 1;
        }
        return output;
    }

    // from https://stackoverflow.com/questions/23457754/how-to-flip-bufferedimage-in-java
    // simple code using AffineTransform to flip the image. Somewhere along the way
    // I must of accidentally done this vertically in the coding process.


    private static BufferedImage createFlipped(BufferedImage image)
    {
        AffineTransform at = new AffineTransform();
        at.concatenate(AffineTransform.getScaleInstance(1, -1));
        at.concatenate(AffineTransform.getTranslateInstance(0, -image.getHeight()));
        return createTransformed(image, at);
    }
    private static BufferedImage createTransformed(
            BufferedImage image, AffineTransform at)
    {
        BufferedImage newImage = new BufferedImage(
                image.getWidth(), image.getHeight(),
                BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = newImage.createGraphics();
        g.transform(at);
        g.drawImage(image, 0, 0, null);
        g.dispose();
        return newImage;
    }

    public static void main(String[] args){
        StringBuilder output = new StringBuilder();

        File file = new File(System.getProperty("user.home")+"/Desktop/toprint.png");
        if(!file.exists()){
            String other = file.getAbsolutePath();
            file = new File(file.getParentFile(), "toprint.jpg");
            if(!file.exists()){
                System.out.println("Image not found.");
                System.exit(0);
            }
        }

        try {
            BufferedImage img = ImageIO.read(file);
            int width = (img.getWidth()), height = (img.getHeight());

            System.out.println("Please specify the desired dimensions, in blocks, of the image.");
            System.out.println("Format: \"2 3\" means 2 wide and 3 tall.");
            // get input
            Scanner scanner = new Scanner(System.in);
            String rawInput = scanner.nextLine();
            // split by space
            String[] delimInput = rawInput.split("\\s");
            // convert to int
            int[] intInput = {0, 0} ;
            for(int i=0;i<2;i++){
                intInput[i] = Integer.parseInt(delimInput[i]);
                if(intInput[i] == 0) {
                    throw new IOException();
                }
                intInput[i] *= RESOLUTION_LIMIT;
            }


            if(width % RESOLUTION_LIMIT != 0 || height % RESOLUTION_LIMIT != 0){
                // need to resize image to fit in boundaries of OC printing
                // which is PIXEL_RESOLUTION^2 per square
                img = resize(img,
                        width - (width % RESOLUTION_LIMIT),
                        height - (height % RESOLUTION_LIMIT));
            }
            img = resize(img, intInput[0] , intInput[1]);
            img = createFlipped(img);

            // add the digits of X and Y - we are doing inhouse IO
            output.append(getDigits(intInput[0] ) + getDigits(intInput[1] )).append(",");

            // add the X and Y size in pixels to the start of the file
            output.append(intInput[0]).append(",").append(intInput[1]).append(",");

            for(int i = 0;i < intInput[1]; i++){
                for(int j = 0; j < intInput[0]; j++){
                    // also convert to hex
                    int colour = img.getRGB(j, i);
                    Color colourObj = new Color(colour);

                    // partial transparency: if any of the channels is 0 then remove the
                    output.append(String.format("%02x%02x%02x", colourObj.getRed(), colourObj.getGreen(), colourObj.getBlue()))
                            .append(",");
                }
            }

            // truncate the last + on the end
            output = new StringBuilder(output.substring(0, output.length() - 1));


        } catch (IOException e) {
            System.out.println("Bad input.");
            e.printStackTrace();
        }

        Toolkit.getDefaultToolkit().getSystemClipboard().setContents(new StringSelection(output.toString()), null);
        System.out.println("Done, you can insert it now into a file and then print it :)");
    }

}

