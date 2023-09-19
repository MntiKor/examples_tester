#include <vtkCamera.h>
#include <vtkImageActor.h>
#include <vtkImageExtractComponents.h>
#include <vtkImageMapper3D.h>
#include <vtkImageRGBToHSV.h>
#include <vtkImageReader2.h>
#include <vtkImageReader2Factory.h>
#include <vtkInteractorStyleImage.h>
#include <vtkNamedColors.h>
#include <vtkNew.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkRenderer.h>
#include <vtkSmartPointer.h>

int main(int argc, char* argv[])
{
  vtkNew<vtkNamedColors> colors;

  // Verify command line arguments.
  if (argc != 2)
  {
    std::cerr << "Usage: " << argv[0] << "image e.g. Gourds2.jpg" << std::endl;
    return EXIT_FAILURE;
  }

  // Read the image.
  vtkNew<vtkImageReader2Factory> readerFactory;
  vtkSmartPointer<vtkImageReader2> reader;
  reader.TakeReference(readerFactory->CreateImageReader2(argv[1]));
  reader->SetFileName(argv[1]);

  vtkNew<vtkImageRGBToHSV> hsvFilter;
  hsvFilter->SetInputConnection(reader->GetOutputPort());

  vtkNew<vtkImageExtractComponents> extractHueFilter;
  extractHueFilter->SetInputConnection(hsvFilter->GetOutputPort());
  extractHueFilter->SetComponents(0);

  vtkNew<vtkImageExtractComponents> extractSaturationFilter;
  extractSaturationFilter->SetInputConnection(hsvFilter->GetOutputPort());
  extractSaturationFilter->SetComponents(1);

  vtkNew<vtkImageExtractComponents> extractValueFilter;
  extractValueFilter->SetInputConnection(hsvFilter->GetOutputPort());
  extractValueFilter->SetComponents(2);

  // Create actors.
  vtkNew<vtkImageActor> inputActor;
  inputActor->GetMapper()->SetInputConnection(reader->GetOutputPort());

  vtkNew<vtkImageActor> hActor;
  hActor->GetMapper()->SetInputConnection(extractHueFilter->GetOutputPort());

  vtkNew<vtkImageActor> sActor;
  sActor->GetMapper()->SetInputConnection(
      extractSaturationFilter->GetOutputPort());

  vtkNew<vtkImageActor> vActor;
  vActor->GetMapper()->SetInputConnection(extractValueFilter->GetOutputPort());

  // Define viewport ranges.
  // (xmin, ymin, xmax, ymax)
  double inputViewport[4] = {0.0, 0.0, 0.25, 1.0};
  double hViewport[4] = {0.25, 0.0, 0.5, 1.0};
  double sViewport[4] = {0.5, 0.0, 0.75, 1.0};
  double vViewport[4] = {0.75, 0.0, 1.0, 1.0};

  // Shared camera.
  vtkNew<vtkCamera> sharedCamera;

  // Setup renderers.
  vtkNew<vtkRenderer> inputRenderer;
  inputRenderer->SetViewport(inputViewport);
  inputRenderer->AddActor(inputActor);
  inputRenderer->SetActiveCamera(sharedCamera);
  inputRenderer->SetBackground(colors->GetColor3d("CornflowerBlue").GetData());

  vtkNew<vtkRenderer> hRenderer;
  hRenderer->SetViewport(hViewport);
  hRenderer->AddActor(hActor);
  hRenderer->SetActiveCamera(sharedCamera);
  hRenderer->SetBackground(colors->GetColor3d("MistyRose").GetData());

  vtkNew<vtkRenderer> sRenderer;
  sRenderer->SetViewport(sViewport);
  sRenderer->AddActor(sActor);
  sRenderer->SetActiveCamera(sharedCamera);
  sRenderer->SetBackground(colors->GetColor3d("LavenderBlush").GetData());

  vtkNew<vtkRenderer> vRenderer;
  vRenderer->SetViewport(vViewport);
  vRenderer->AddActor(vActor);
  vRenderer->SetActiveCamera(sharedCamera);
  vRenderer->SetBackground(colors->GetColor3d("Lavender").GetData());

  // Setup render window.
  vtkNew<vtkRenderWindow> renderWindow;
  renderWindow->SetSize(1000, 250);
  renderWindow->SetWindowName("RGBToHSV");
  renderWindow->AddRenderer(inputRenderer);
  renderWindow->AddRenderer(hRenderer);
  renderWindow->AddRenderer(sRenderer);
  renderWindow->AddRenderer(vRenderer);
  inputRenderer->ResetCamera();

  // Setup render window interactor.
  vtkNew<vtkRenderWindowInteractor> renderWindowInteractor;
  vtkNew<vtkInteractorStyleImage> style;

  renderWindowInteractor->SetInteractorStyle(style);

  // Render and start interaction.
  renderWindowInteractor->SetRenderWindow(renderWindow);
  renderWindow->Render();
  renderWindowInteractor->Initialize();

  renderWindowInteractor->Start();

  return EXIT_SUCCESS;
}
