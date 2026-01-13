import '../../models/quotations/quotation_model.dart';
import '../../models/service_tasks/service_task_model.dart';
import '../../repositories/quotations/quotation_repository.dart';
import '../../repositories/service_tasks/service_task_repository.dart';

class ContractorGenerateQuotationController {
  final ServiceTaskRepository _tasksRepo;
  final QuotationRepository _quotationRepo;

  ContractorGenerateQuotationController({
    ServiceTaskRepository? tasksRepo,
    QuotationRepository? quotationRepo,
  })  : _tasksRepo = tasksRepo ?? ServiceTaskRepository(),
        _quotationRepo = quotationRepo ?? QuotationRepository();

  Future<List<ServiceTaskModel>> fetchTasksForCategory(String category) {
    return _tasksRepo.fetchByCategory(category);
  }

  int computePlatformFee2Percent(int serviceTotal) => (serviceTotal * 0.02).round();

  Future<void> submitQuotation({
    required String jobId,
    required String contractorId,
    required int visitationFee,
    required List<QuotationTaskLine> lines,
  }) async {
    final serviceTotal = lines.fold(0, (sum, l) => sum + l.lineTotal);
    final platformFee = computePlatformFee2Percent(serviceTotal);
    final totalAmount = serviceTotal + visitationFee + platformFee;

    final pricing = QuotationPricing(
      platformFee: platformFee,
      serviceTotal: serviceTotal,
      totalAmount: totalAmount,
      visitationFee: visitationFee,
    );

    await _quotationRepo.createQuotation(
      jobId: jobId,
      contractorId: contractorId,
      pricing: pricing,
      tasks: lines,
    );
  }
}
