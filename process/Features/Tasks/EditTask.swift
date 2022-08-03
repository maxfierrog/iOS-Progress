//
//  NewTask.swift
//  process
//
//  Created by Maximo Fierro on 7/11/22.
//


import SwiftUI


/** Screen where users either create a new task or edit an existing one,
 depending on parameters passed in the view constructor. */
struct EditTaskView: View {
    
    @ObservedObject var model: EditTaskViewModel
    
    var body: some View {
        VStack {
            GroupBox {
                TextField("Task Title", text: $model.titleField)
                    .disableAutocorrection(true)
                    .autocapitalization(.sentences)
                    .font(.title2.bold())
                    .padding(.top, 8)
                    .padding(.bottom, 8)
            }
            .padding(.top)
            .padding(.leading)
            .padding(.trailing)
            
            GroupBox {
                TextField("Write a brief summary of your task...", text: $model.descriptionField)
                    .disableAutocorrection(true)
                    .autocapitalization(.sentences)
                    .font(.body.weight(.semibold))
                    .padding(.top, 8)
                    .padding(.bottom, 8)
            } label: {
                Text("Description:")
            }
            .padding(.top)
            .padding(.leading)
            .padding(.trailing)
            
            GroupBox {
                Button {
                    model.toProject = nil
                    model.toProjectName = "None"
                } label: {
                    Text("None")
                }
                .buttonStyle(.bordered)
                ScrollView(.vertical) {
                    ForEach($model.user.data.allProjects.indices, id: \.self) { index in
                        ProjectsListItemView(model: ProjectPickerViewModel(projectID: model.user.data.allProjects[index], parentModel: model))
                    }
                }
            } label: {
                Text("Assigned to:  \(model.toProjectName)")
            }
            .padding(.top)
            .padding(.leading)
            .padding(.trailing)

            Spacer()
        }
        .navigationTitle("New Task")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    model.tappedSave()
                } label: {
                    Text("Save")
                }
                .buttonStyle(.bordered)
            }
            
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    model.tappedCancel()
                } label: {
                    Text("Cancel")
                }
            }
        }
        .accentColor(GlobalConstant.accentColor)
    }
}


/** */
class EditTaskViewModel: ObservableObject {
    
    /* MARK: Model fields */
    
    // Fields
    @Published var titleField: String = ""
    @Published var descriptionField: String = ""
    @Published var size: Int = 1 // FIXME: !
    @Published var dateDue: Date = Date() // FIXME: !
    @Published var toProject: String? = nil // FIXME: !
    @Published var toProjectName: String = "None"
    
    // Projects home view parent model
    var parentModel: TaskListViewModel
    @Published var user: User
    @Published var editingTask: Task?
    
    // Banner state fields
    @Published var bannerData: BannerModifier.BannerData = BannerModifier.BannerData(title: "", detail: "", type: .Info)
    @Published var showBanner: Bool = false
    
    /* MARK: Model methods */
    
    init(_ model: TaskListViewModel, isNewTask: Bool) {
        self.parentModel = model
        self.user = model.user
        if !isNewTask {
            self.editingTask = model.selectedTask
            self.titleField = model.selectedTask.data.name
            self.descriptionField = model.selectedTask.data.description ?? ""
            self.size = model.selectedTask.data.size
            self.toProject = model.selectedTask.data.project
            self.dateDue = model.selectedTask.data.dateDue
        }
    }
    
    func tappedSave() {
        let newTask = self.editingTask ?? Task(creatorID: self.user.data.id)
        
        self.user
            .addTask(newTask.data.id)
            .push { error in
                guard error == nil else {
                    self.showBannerWithErrorMessage(error?.localizedDescription)
                    return
                }
                newTask
                    .changeName(self.titleField)
                    .changeSize(self.size)
                    .changeDescription(self.descriptionField)
                    .changeDateDue(self.dateDue)
                    .changeAssignee(self.user.data.id)
                    .changeProject(self.toProject)
                    .push { error in
                        guard error == nil else {
                            self.showBannerWithErrorMessage(error?.localizedDescription)
                            return
                        }
                        self.user.refreshTaskList().finishEdit()
                        self.dismissView(successBanner: "We have created and saved your new task!")
                    }
                }
    }
    
    func tappedCancel() {
        self.parentModel.dismissEditTaskView()
    }
    
    func setToProject(_ project: Project) {
        self.toProject = project.data.id
        self.toProjectName = project.data.name
    }
    
    /* MARK: Helper methods */
    
    private func showBannerWithErrorMessage(_ message: String?) {
        guard let message = message else { return }
        bannerData.title = GlobalConstant.genericErrorBannerTitle
        bannerData.detail = message
        bannerData.type = .Error
        showBanner = true
    }
    
    private func dismissView(successBanner: String?) {
        self.parentModel.dismissEditTaskView()
        guard successBanner == nil else {
            self.parentModel.showBannerWithSuccessMessage(successBanner)
            return
        }
    }
}
