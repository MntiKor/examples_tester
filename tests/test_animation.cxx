#include <vtkCallbackCommand.h>
#include <vtkCommand.h>
#include <vtkHDFReader.h>
#include <vtkInteractorStyleTrackballCamera.h>
#include <vtkLookupTable.h>
#include <vtkNamedColors.h>
#include <vtkNew.h>
#include <vtkObject.h>
#include <vtkObjectBase.h>
#include <vtkPointData.h>
#include <vtkPolyData.h>
#include <vtkPolyDataMapper.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkRenderer.h>

#include <cstdlib>

namespace {
void Animate(vtkObject *caller, unsigned long eid, void *clientdata,
             void *calldata);
} // namespace

int main(int ac, char *av[]) {
  vtkNew<vtkRenderer> renderer;
  renderer->SetBackground(colors->GetColor3d("Wheat").GetData());
  renderer->UseHiddenLineRemovalOn();

  vtkNew<vtkRenderWindow> renWin;
  renWin->AddRenderer(renderer);
  renWin->SetWindowName("TransientHDFReader");
  renWin->SetSize(1024, 512);
  renWin->Render();

  // Add the interactor.
  vtkNew<vtkRenderWindowInteractor> iren;
  iren->SetRenderWindow(renWin);

  // Add the animation callback.
  vtkNew<vtkCallbackCommand> command;
  command->SetCallback(&Animate);
  command->SetClientData(reader);

  iren->AddObserver(vtkCommand::TimerEvent, command);
  iren->CreateRepeatingTimer(50);

  vtkNew<vtkInteractorStyleTrackballCamera> istyle;
  iren->SetInteractorStyle(istyle);

  iren->Start();

  return EXIT_SUCCESS;
}

namespace {
void Animate(vtkObject *caller, unsigned long eid, void *clientdata,
             void *calldata) {
  vtkRenderWindowInteractor *interactor =
      vtkRenderWindowInteractor::SafeDownCast(caller);
  std::cout << "This is an animation" << std::endl;
  reader->Update();
  interactor->Render();
}
} // namespace
